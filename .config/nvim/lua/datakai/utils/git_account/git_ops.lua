-- Git Operations Module for git_account
-- Handles git commands and repository operations

local M = {}

-- Import cross-platform utilities
local platform = require('datakai.utils.platform')

-- Helper function to run git commands and handle errors
M.run_git_cmd = function(cmd, silent)
    return platform.system("git " .. cmd, silent)
end

-- Check if we're in a git repository
M.in_git_repo = function()
    local _, exit_code = M.run_git_cmd("rev-parse --is-inside-work-tree", true)
    return exit_code == 0
end

-- Switch Git account
M.switch_account = function()
    local core = require('datakai.utils.git_account.core')
    local ssh_module = require('datakai.utils.git_account.ssh')

    -- Check if we have accounts configured
    if vim.tbl_isempty(core.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            core.add_account()
        end
        return
    end

    -- Get current identity for highlighting current selection
    local current_identity = nil
    local current_account = nil

    if M.in_git_repo() then
        current_identity = core.get_current_identity()
        current_account = core.find_account_by_identity(current_identity)
    end

    -- Get account names and sort them
    local account_names = {}
    for name, _ in pairs(core.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Format items with current selection indicator
    local format_item = function(item)
        if item == current_account then
            return item .. " (current)"
        else
            return item
        end
    end

    -- Show selection menu
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
        format_item = format_item
    }, function(selected)
        if selected then
            local account = core.accounts[selected]

            -- Set Git config
            vim.fn.system("git config user.name '" .. account.name .. "'")
            vim.fn.system("git config user.email '" .. account.email .. "'")

            -- Configure SSH if host is specified
            local ssh_configured = false
            if account.ssh_host then
                ssh_configured = ssh_module.configure_git_ssh(account, core.config.ssh_config_path)
            end

            -- Get current config for confirmation
            local name = vim.fn.system("git config user.name"):gsub("\n", "")
            local email = vim.fn.system("git config user.email"):gsub("\n", "")

            -- Confirmation message with SSH info
            local msg = "Git account switched to: " .. name .. " <" .. email .. ">"
            if ssh_configured then
                msg = msg .. " (Using SSH host: " .. account.ssh_host .. ")"
            end

            vim.notify(msg, vim.log.levels.INFO)
        end
    end)
end

-- Create a new worktree with specific config
M.create_worktree = function()
    local core = require('datakai.utils.git_account.core')

    -- Check if we have accounts configured
    if vim.tbl_isempty(core.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            core.add_account()
        end
        return
    end

    -- Check if git-worktree is available
    local _, worktree_exit = M.run_git_cmd("worktree", true)
    if worktree_exit ~= 0 then
        vim.notify("git-worktree is not available. Please install it first.", vim.log.levels.ERROR)
        return
    end

    -- Check if in a git repository
    if not M.in_git_repo() then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end

    -- Get branch name
    local branch = vim.fn.input({
        prompt = "New branch name: ",
        default = "",
        completion = "customlist,v:lua.require'datakai.utils.git_helpers'.list_branches"
    })

    if branch == "" then return end

    -- Get worktree path - use platform-specific path handling
    local default_path = platform.normalize_path(vim.fn.getcwd() .. "/../" .. branch)
    local path = vim.fn.input({
        prompt = "Worktree path: ",
        default = default_path,
        completion = "dir"
    })

    if path == "" then return end

    -- Normalize path for the OS
    path = platform.normalize_path(path)

    -- Get account names
    local account_names = {}
    for name, _ in pairs(core.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Show selection menu for accounts
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
    }, function(selected)
        if selected then
            local account = core.accounts[selected]

            -- Create the worktree
            local output, exit_code = M.run_git_cmd(
                string.format("worktree add -b %s %s",
                    vim.fn.shellescape(branch),
                    vim.fn.shellescape(path))
            )

            if exit_code ~= 0 then
                vim.notify("Failed to create worktree:\n" .. output, vim.log.levels.ERROR)
                return
            end

            -- Configure client-specific Git settings - use platform-specific commands
            local cmds = {}

            if platform.os == "windows" then
                -- Windows commands
                table.insert(cmds, string.format("cd /d %s", vim.fn.shellescape(path)))
            else
                -- Unix commands
                table.insert(cmds, string.format("cd %s", vim.fn.shellescape(path)))
            end

            table.insert(cmds, string.format("git config user.name '%s'", account.name))
            table.insert(cmds, string.format("git config user.email '%s'", account.email))

            -- Configure SSH if host is specified
            if account.ssh_host then
                if platform.os == "windows" then
                    -- Windows SSH config
                    table.insert(cmds, string.format("git config core.sshCommand 'ssh -i %s'",
                        vim.fn.shellescape(account.ssh_key)))
                else
                    -- Unix SSH config
                    table.insert(cmds, string.format("git config core.sshCommand 'ssh -F %s %s'",
                        vim.fn.shellescape(vim.fn.expand(core.config.ssh_config_path)),
                        account.ssh_host))
                end
            end

            -- Run commands
            local cmd = table.concat(cmds, platform.os == "windows" and " && " or " && ")
            vim.fn.system(cmd)

            -- Success message
            local msg = string.format(
                "Created worktree at %s with account %s <%s>",
                path, account.name, account.email
            )

            if account.ssh_host then
                msg = msg .. " (Using SSH host: " .. account.ssh_host .. ")"
            end

            vim.notify(msg, vim.log.levels.INFO)

            -- Ask if user wants to switch to the new worktree
            vim.defer_fn(function()
                if vim.fn.confirm("Switch to the new worktree?", "&Yes\n&No") == 1 then
                    vim.cmd("cd " .. vim.fn.shellescape(path))
                    vim.notify("Switched to " .. path, vim.log.levels.INFO)
                end
            end, 100)
        end
    end)
end

-- Initialize a new Git repository with specific identity
M.init_repo = function()
    local core = require('datakai.utils.git_account.core')
    local ssh_module = require('datakai.utils.git_account.ssh')

    -- Check if we have accounts configured
    if vim.tbl_isempty(core.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            core.add_account()
        end
        return
    end

    -- Get account names and sort them
    local account_names = {}
    for name, _ in pairs(core.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Ask for template if available
    local templates = {}
    local templates_dir = vim.fn.expand(core.config.templates_dir)

    if vim.fn.isdirectory(templates_dir) == 1 then
        local command = platform.os == "windows"
            and "dir /b " .. vim.fn.shellescape(templates_dir)
            or "ls -1 " .. vim.fn.shellescape(templates_dir)

        local handle = io.popen(command)
        if handle then
            for line in handle:lines() do
                table.insert(templates, line)
            end
            handle:close()
        end
    end

    -- Prepare options for template selection
    local template_prompt = #templates > 0 and
        "Select template (optional):" or
        "No templates available"

    local template_opts = {
        prompt = template_prompt,
    }
    if #templates == 0 then
        table.insert(templates, "None")
    else
        table.insert(templates, 1, "None")
    end

    -- First ask for account
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
    }, function(selected_account)
        if not selected_account then return end

        local account = core.accounts[selected_account]

        -- Then ask for template
        vim.ui.select(templates, template_opts, function(selected_template)
            if not selected_template or selected_template == "None" then
                selected_template = nil
            end

            -- Initialize Git repository
            local output, exit_code = M.run_git_cmd("init", false)
            if exit_code ~= 0 then
                vim.notify("Failed to initialize repository:\n" .. output, vim.log.levels.ERROR)
                return
            end

            -- Set local Git config
            vim.fn.system("git config user.name '" .. account.name .. "'")
            vim.fn.system("git config user.email '" .. account.email .. "'")

            -- Configure SSH if host is specified
            local ssh_configured = false
            if account.ssh_host then
                ssh_configured = ssh_module.configure_git_ssh(account, core.config.ssh_config_path)
            end

            -- Apply template if selected
            if selected_template then
                local template_path = core.config.templates_dir .. platform.get_separator() .. selected_template

                -- Copy template files
                if vim.fn.isdirectory(vim.fn.expand(template_path)) == 1 then
                    -- Platform-specific copy command
                    local copy_cmd = platform.os == "windows"
                        and "xcopy /E /Y " .. vim.fn.shellescape(vim.fn.expand(template_path)) .. "\\* ."
                        or "cp -r " .. vim.fn.shellescape(vim.fn.expand(template_path)) .. "/* ."

                    vim.fn.system(copy_cmd)
                    vim.notify("Applied template: " .. selected_template, vim.log.levels.INFO)
                end
            end

            -- Add git hooks if available
            local hooks_dir = vim.fn.expand(core.config.hooks_dir)
            if vim.fn.isdirectory(hooks_dir) == 1 then
                -- Ensure .git/hooks exists
                local git_hooks_dir = ".git/hooks"
                platform.ensure_directory(git_hooks_dir)

                -- Platform-specific copy command
                local copy_cmd = platform.os == "windows"
                    and "xcopy /E /Y " .. vim.fn.shellescape(hooks_dir) .. "\\* " .. git_hooks_dir .. "\\"
                    or "cp -r " .. vim.fn.shellescape(hooks_dir) .. "/* " .. git_hooks_dir .. "/"

                vim.fn.system(copy_cmd)

                -- Make hooks executable on Unix-like systems
                if platform.os ~= "windows" then
                    vim.fn.system("chmod +x " .. git_hooks_dir .. "/*")
                end

                vim.notify("Added git hooks from " .. core.config.hooks_dir, vim.log.levels.INFO)
            end

            -- Get current config for confirmation
            local name = vim.fn.system("git config user.name"):gsub("\n", "")
            local email = vim.fn.system("git config user.email"):gsub("\n", "")

            -- Success message
            local msg = "Git repository initialized with account: " .. name .. " <" .. email .. ">"
            if ssh_configured then
                msg = msg .. " (Using SSH host: " .. account.ssh_host .. ")"
            end
            if selected_template then
                msg = msg .. "\nTemplate: " .. selected_template
            end

            vim.notify(msg, vim.log.levels.INFO)

            -- Offer to create initial commit
            vim.defer_fn(function()
                if vim.fn.confirm("Create initial commit?", "&Yes\n&No") == 1 then
                    local commit_msg = vim.fn.input({
                        prompt = "Commit message: ",
                        default = "Initial commit"
                    })

                    if commit_msg ~= "" then
                        -- Stage all files
                        vim.fn.system("git add .")

                        -- Commit
                        local commit_output = vim.fn.system("git commit -m " ..
                            vim.fn.shellescape(commit_msg))

                        vim.notify("Initial commit created:\n" .. commit_output, vim.log.levels.INFO)
                    end
                end
            end, 100)
        end)
    end)
end

-- List git worktrees
M.list_worktrees = function()
    -- Check if in a git repository
    if not M.in_git_repo() then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return
    end

    -- Get worktrees
    local output, exit_code = M.run_git_cmd("worktree list", false)
    if exit_code ~= 0 then return end

    local lines = {
        "Git Worktrees:",
        "-------------",
        ""
    }

    -- Add each worktree
    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Create buffer and display worktrees
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, "Git Worktrees")

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "c",
        [[<cmd>lua require('datakai.utils.git_account').create_worktree()<CR>]],
        { noremap = true, silent = true, desc = "Create worktree" })
end

return M
