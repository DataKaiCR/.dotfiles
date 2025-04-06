local M = {}

-- Default configuration
M.config = {
    accounts_file = os.getenv("HOME") .. "/.config/nvim/git_accounts.lua",
    ssh_config_path = os.getenv("HOME") .. "/.ssh/config",
    templates_dir = os.getenv("HOME") .. "/.config/git/templates",
    hooks_dir = os.getenv("HOME") .. "/.config/git/hooks"
}

-- Empty accounts table - will be populated from accounts file if it exists
M.accounts = {}

-- Parse SSH config and extract hosts with their identity files
M.parse_ssh_config = function()
    local ssh_hosts = {}
    local current_host = nil

    -- Check if SSH config exists
    if vim.fn.filereadable(vim.fn.expand(M.config.ssh_config_path)) ~= 1 then
        return ssh_hosts
    end

    -- Read SSH config file
    local lines = vim.fn.readfile(vim.fn.expand(M.config.ssh_config_path))

    for _, line in ipairs(lines) do
        -- Remove comments and trim
        line = line:gsub("#.*$", ""):gsub("^%s*(.-)%s*$", "%1")

        if line ~= "" then
            -- Check if it's a Host line
            local host = line:match("^Host%s+(.+)$")
            if host then
                current_host = host
                ssh_hosts[current_host] = {}
            end

            -- If we're in a Host block, look for IdentityFile
            if current_host then
                local identity_file = line:match("^%s*IdentityFile%s+(.+)$")
                if identity_file then
                    ssh_hosts[current_host].identity_file = identity_file:gsub("^~", os.getenv("HOME"))
                end

                -- Look for other useful options like User
                local user = line:match("^%s*User%s+(.+)$")
                if user then
                    ssh_hosts[current_host].user = user
                end
            end
        end
    end

    return ssh_hosts
end

-- Initialize the module with custom config
M.setup = function(opts)
    opts = opts or {}

    -- Apply any provided configuration
    for k, v in pairs(opts) do
        M.config[k] = v
    end

    -- Parse SSH config first
    M.ssh_hosts = M.parse_ssh_config()

    -- Try to load accounts from file if it exists
    local accounts_file = M.config.accounts_file
    if vim.fn.filereadable(vim.fn.expand(accounts_file)) == 1 then
        local success, accounts = pcall(dofile, vim.fn.expand(accounts_file))
        if success and type(accounts) == "table" then
            M.accounts = accounts
        else
            vim.notify("Failed to load git accounts from " .. accounts_file, vim.log.levels.WARN)
        end
    end

    -- Update account SSH information from SSH config
    for name, account in pairs(M.accounts) do
        if account.ssh_host and M.ssh_hosts[account.ssh_host] then
            account.ssh_key = M.ssh_hosts[account.ssh_host].identity_file
            account.ssh_user = M.ssh_hosts[account.ssh_host].user
        end
    end

    return M
end

-- Helper function to run git commands and handle errors
M.run_git_cmd = function(cmd, silent)
    local output = vim.fn.system("git " .. cmd)
    local exit_code = vim.v.shell_error

    if not silent and exit_code ~= 0 then
        vim.notify("Git command failed: " .. cmd .. "\n" .. output, vim.log.levels.ERROR)
    end

    return output, exit_code
end

-- Get current git identity
M.get_current_identity = function()
    local name, name_exit = M.run_git_cmd("config user.name", true)
    local email, email_exit = M.run_git_cmd("config user.email", true)

    if name_exit ~= 0 or email_exit ~= 0 then
        return nil
    end

    return {
        name = name:gsub("\n", ""),
        email = email:gsub("\n", "")
    }
end

-- Check if we're in a git repository
M.in_git_repo = function()
    local _, exit_code = M.run_git_cmd("rev-parse --is-inside-work-tree", true)
    return exit_code == 0
end

-- Find account by name or email
M.find_account_by_identity = function(identity)
    if not identity then return nil end

    for name, account in pairs(M.accounts) do
        if account.name == identity.name and account.email == identity.email then
            return name
        end
    end

    return nil
end

-- Configure git with SSH host
M.configure_git_ssh = function(account)
    if not account.ssh_host then return false end

    -- Set core.sshCommand to use the SSH host
    -- This uses SSH config for the host, including the identity file
    local cmd = string.format("git config core.sshCommand 'ssh -F %s %s'",
        vim.fn.shellescape(vim.fn.expand(M.config.ssh_config_path)),
        account.ssh_host)

    local exit_code = os.execute(cmd)
    return exit_code == 0
end

-- Switch Git account
M.switch_account = function()
    -- Check if we have accounts configured
    if vim.tbl_isempty(M.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            M.add_account()
        end
        return
    end

    -- Get current identity for highlighting current selection
    local current_identity = nil
    local current_account = nil

    if M.in_git_repo() then
        current_identity = M.get_current_identity()
        current_account = M.find_account_by_identity(current_identity)
    end

    -- Get account names and sort them
    local account_names = {}
    for name, _ in pairs(M.accounts) do
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
            local account = M.accounts[selected]

            -- Set Git config
            vim.fn.system("git config user.name '" .. account.name .. "'")
            vim.fn.system("git config user.email '" .. account.email .. "'")

            -- Configure SSH if host is specified
            local ssh_configured = false
            if account.ssh_host then
                ssh_configured = M.configure_git_ssh(account)
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
    -- Check if we have accounts configured
    if vim.tbl_isempty(M.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            M.add_account()
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

    -- Get worktree path
    local default_path = vim.fn.getcwd() .. "/../" .. branch
    local path = vim.fn.input({
        prompt = "Worktree path: ",
        default = default_path,
        completion = "dir"
    })

    if path == "" then return end

    -- Get account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Show selection menu for accounts
    vim.ui.select(account_names, {
        prompt = "Select Git Account:",
    }, function(selected)
        if selected then
            local account = M.accounts[selected]

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

            -- Configure client-specific Git settings
            local cmds = {
                string.format("cd %s", vim.fn.shellescape(path)),
                string.format("git config user.name '%s'", account.name),
                string.format("git config user.email '%s'", account.email)
            }

            -- Configure SSH if host is specified
            if account.ssh_host then
                table.insert(cmds, string.format("git config core.sshCommand 'ssh -F %s %s'",
                    vim.fn.shellescape(vim.fn.expand(M.config.ssh_config_path)),
                    account.ssh_host))
            end

            -- Run commands
            local cmd = table.concat(cmds, " && ")
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
    -- Check if we have accounts configured
    if vim.tbl_isempty(M.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            M.add_account()
        end
        return
    end

    -- Get account names and sort them
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Ask for template if available
    local templates = {}
    if vim.fn.isdirectory(vim.fn.expand(M.config.templates_dir)) == 1 then
        local handle = io.popen("ls -1 " .. vim.fn.shellescape(vim.fn.expand(M.config.templates_dir)))
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

        local account = M.accounts[selected_account]

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
                ssh_configured = M.configure_git_ssh(account)
            end

            -- Apply template if selected
            if selected_template then
                local template_path = M.config.templates_dir .. "/" .. selected_template

                -- Copy template files
                if vim.fn.isdirectory(vim.fn.expand(template_path)) == 1 then
                    vim.fn.system("cp -r " .. vim.fn.shellescape(vim.fn.expand(template_path)) .. "/* .")
                    vim.notify("Applied template: " .. selected_template, vim.log.levels.INFO)
                end
            end

            -- Add git hooks if available
            if vim.fn.isdirectory(vim.fn.expand(M.config.hooks_dir)) == 1 then
                vim.fn.system("mkdir -p .git/hooks")
                vim.fn.system("cp -r " .. vim.fn.shellescape(vim.fn.expand(M.config.hooks_dir)) .. "/* .git/hooks/")
                vim.fn.system("chmod +x .git/hooks/*")
                vim.notify("Added git hooks from " .. M.config.hooks_dir, vim.log.levels.INFO)
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

-- List all SSH hosts in the config
M.list_ssh_hosts = function()
    local lines = {
        "SSH Hosts in Config:",
        "-------------------",
        ""
    }

    -- Sort hosts
    local host_names = {}
    for host, _ in pairs(M.ssh_hosts) do
        table.insert(host_names, host)
    end
    table.sort(host_names)

    -- Add details for each host
    for _, host in ipairs(host_names) do
        local info = M.ssh_hosts[host]
        table.insert(lines, "Host: " .. host)

        if info.identity_file then
            table.insert(lines, "  IdentityFile: " .. info.identity_file)
        end

        if info.user then
            table.insert(lines, "  User: " .. info.user)
        end

        table.insert(lines, "")
    end

    -- Create buffer and display hosts
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, "SSH Hosts")

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "a",
        [[<cmd>lua require('datakai.utils.git_account').add_account()<CR>]],
        { noremap = true, silent = true, desc = "Add account" })
end

-- Add a new account
M.add_account = function()
    -- Get account details
    local display_name = vim.fn.input({
        prompt = "Account display name: ",
    })

    if display_name == "" then return end

    local name = vim.fn.input({
        prompt = "Git username: ",
    })

    if name == "" then return end

    local email = vim.fn.input({
        prompt = "Git email: ",
    })

    if email == "" then return end

    -- Get SSH host names
    local host_names = { "None" }
    for host, _ in pairs(M.ssh_hosts) do
        table.insert(host_names, host)
    end
    table.sort(host_names, function(a, b)
        if a == "None" then
            return true
        elseif b == "None" then
            return false
        else
            return a < b
        end
    end)

    -- Show selection menu for SSH hosts
    vim.ui.select(host_names, {
        prompt = "Select SSH Host (or None):",
    }, function(selected_host)
        if not selected_host then return end

        local ssh_host = selected_host ~= "None" and selected_host or nil

        -- Add the account
        M.accounts[display_name] = {
            name = name,
            email = email,
            ssh_host = ssh_host
        }

        -- Update SSH key from config if host is specified
        if ssh_host and M.ssh_hosts[ssh_host] then
            M.accounts[display_name].ssh_key = M.ssh_hosts[ssh_host].identity_file
            M.accounts[display_name].ssh_user = M.ssh_hosts[ssh_host].user
        end

        -- Save accounts to file
        M.save_accounts()

        -- Confirmation message
        local msg = "Added new account: " .. display_name .. " (" .. name .. " <" .. email .. ">)"
        if ssh_host then
            msg = msg .. " using SSH host: " .. ssh_host
        end

        vim.notify(msg, vim.log.levels.INFO)
    end)
end

-- Save accounts to file
M.save_accounts = function()
    local accounts_file = vim.fn.expand(M.config.accounts_file)

    -- Create directory if it doesn't exist
    local dir = vim.fn.fnamemodify(accounts_file, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        vim.fn.mkdir(dir, "p")
    end

    -- Format accounts as Lua code
    local lines = {
        "-- Git accounts configuration",
        "-- Generated by git_account.lua",
        "-- Maps to SSH hosts in " .. M.config.ssh_config_path,
        "return {"
    }

    -- Sort account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Add each account
    for _, name in ipairs(account_names) do
        local account = M.accounts[name]
        table.insert(lines, string.format('    ["%s"] = {', name))
        table.insert(lines, string.format('        name = "%s",', account.name))
        table.insert(lines, string.format('        email = "%s",', account.email))

        if account.ssh_host then
            table.insert(lines, string.format('        ssh_host = "%s",', account.ssh_host))
        end

        table.insert(lines, "    },")
    end

    table.insert(lines, "}")

    -- Write to file
    local file = io.open(accounts_file, "w")
    if file then
        file:write(table.concat(lines, "\n"))
        file:close()
        vim.notify("Saved accounts to " .. accounts_file, vim.log.levels.INFO)
    else
        vim.notify("Failed to save accounts to " .. accounts_file, vim.log.levels.ERROR)
    end
end

-- Remove an account
M.remove_account = function()
    -- Check if we have accounts configured
    if vim.tbl_isempty(M.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)
        return
    end

    -- Get account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Show selection menu
    vim.ui.select(account_names, {
        prompt = "Select account to remove:",
    }, function(selected)
        if selected then
            -- Confirm removal
            if vim.fn.confirm("Remove account " .. selected .. "?", "&Yes\n&No") == 1 then
                -- Remove the account
                M.accounts[selected] = nil

                -- Save accounts to file
                M.save_accounts()

                vim.notify("Removed account: " .. selected, vim.log.levels.INFO)
            end
        end
    end)
end

-- List all configured accounts
M.list_accounts = function()
    -- Check if we have accounts configured
    if vim.tbl_isempty(M.accounts) then
        vim.notify("No git accounts configured. Please add an account first.", vim.log.levels.WARN)

        -- Ask if user wants to add an account
        if vim.fn.confirm("Add a new account now?", "&Yes\n&No") == 1 then
            M.add_account()
        end
        return
    end

    local lines = {
        "Configured Git Accounts:",
        "----------------------",
        ""
    }

    -- Get current identity
    local current_identity = nil
    local current_account = nil

    if M.in_git_repo() then
        current_identity = M.get_current_identity()
        current_account = M.find_account_by_identity(current_identity)
    end

    -- Sort account names
    local account_names = {}
    for name, _ in pairs(M.accounts) do
        table.insert(account_names, name)
    end
    table.sort(account_names)

    -- Add account details
    for _, name in ipairs(account_names) do
        local account = M.accounts[name]
        local account_line = name .. ":"

        -- Mark current account
        if name == current_account then
            account_line = account_line .. " (current)"
        end

        table.insert(lines, account_line)
        table.insert(lines, "  Name: " .. account.name)
        table.insert(lines, "  Email: " .. account.email)

        if account.ssh_host then
            table.insert(lines, "  SSH Host: " .. account.ssh_host)

            if account.ssh_key then
                table.insert(lines, "  SSH Key: " .. account.ssh_key)
            end

            if account.ssh_user then
                table.insert(lines, "  SSH User: " .. account.ssh_user)
            end
        end

        table.insert(lines, "")
    end

    -- Create buffer and display accounts
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, "Git Accounts")

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", ":bdelete<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "s",
        [[<cmd>lua require('datakai.utils.git_account').switch_account()<CR>]],
        { noremap = true, silent = true, desc = "Switch account" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "h",
        [[<cmd>lua require('datakai.utils.git_account').list_ssh_hosts()<CR>]],
        { noremap = true, silent = true, desc = "List SSH hosts" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "a",
        [[<cmd>lua require('datakai.utils.git_account').add_account()<CR>]],
        { noremap = true, silent = true, desc = "Add account" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "r",
        [[<cmd>lua require('datakai.utils.git_account').remove_account()<CR>]],
        { noremap = true, silent = true, desc = "Remove account" })
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

-- Edit SSH config (opens the config file for editing)
M.edit_ssh_config = function()
    -- Check if SSH config exists
    local config_path = vim.fn.expand(M.config.ssh_config_path)
    if vim.fn.filereadable(config_path) ~= 1 then
        -- Create empty config if it doesn't exist
        local dir = vim.fn.fnamemodify(config_path, ":h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end

        local file = io.open(config_path, "w")
        if file then
            file:write("# SSH Configuration File\n")
            file:write("# Created by git_account.lua\n\n")
            file:close()
        else
            vim.notify("Failed to create SSH config file", vim.log.levels.ERROR)
            return
        end
    end

    -- Open the file for editing
    vim.cmd("edit " .. vim.fn.fnameescape(config_path))

    -- Add autocmd to reload SSH config when the file is written
    vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = vim.fn.fnameescape(config_path),
        callback = function()
            M.ssh_hosts = M.parse_ssh_config()
            vim.notify("SSH config reloaded", vim.log.levels.INFO)

            -- Update account SSH information
            for name, account in pairs(M.accounts) do
                if account.ssh_host and M.ssh_hosts[account.ssh_host] then
                    account.ssh_key = M.ssh_hosts[account.ssh_host].identity_file
                    account.ssh_user = M.ssh_hosts[account.ssh_host].user
                end
            end
        end,
        once = false
    })

    vim.notify("Editing SSH config. Save to reload configuration.", vim.log.levels.INFO)
end

-- Initialize the module with defaults
M.setup()

return M
