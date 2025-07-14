-- dotfiles.lua - Enhanced cross-platform dotfiles management
-- For managing dotfiles across multiple systems using git bare repository approach

local M = {}

-- Import cross-platform utilities
local platform = require('datakai.utils.platform')

-- Configuration settings with platform-specific defaults
M.config = {
    git_dir = platform.normalize_path(platform.get_home() .. "/.dotfiles"),
    work_tree = platform.get_home(),
    ssh_key = platform.normalize_path(platform.get_home() .. "/.ssh/git_datakaicr"),
    default_remote = "origin",
    default_branch = "main",
    buffer_name = "Dotfiles",
}

-- Initialize the module with custom config
M.setup = function(opts)
    opts = opts or {}
    for k, v in pairs(opts) do
        M.config[k] = v
    end

    -- Create base command with proper escaping
    M.base_cmd = string.format(
        "git --git-dir=%s --work-tree=%s",
        vim.fn.shellescape(M.config.git_dir),
        vim.fn.shellescape(M.config.work_tree)
    )

    return M
end

-- Run a dotfiles command and return output and exit status
M.run_cmd = function(cmd, silent)
    local full_cmd = M.base_cmd .. " " .. cmd
    local output, exit_code = platform.system(full_cmd, silent)

    if not silent and exit_code ~= 0 then
        vim.notify(
            "Dotfiles command failed: " .. cmd .. "\n" .. output,
            vim.log.levels.ERROR
        )
    end

    return output, exit_code
end

-- Create or get a buffer for dotfiles operations
M.get_buffer = function(name_suffix)
    local buf_name = M.config.buffer_name
    if name_suffix then
        buf_name = buf_name .. " " .. name_suffix
    end

    -- Check if buffer already exists
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_info = vim.fn.getbufinfo(buf)[1]
        if buf_info.name:match(buf_name .. "$") then
            return buf
        end
    end

    -- Create new buffer
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()

    -- Set buffer options
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, buf_name)

    -- Setup buffer-local keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<ESC>", ":bdelete<CR>", { noremap = true, silent = true })

    return bufnr
end

-- Show dotfiles status in a buffer
M.status = function()
    -- Get current status
    local output, code = M.run_cmd("status")
    if code ~= 0 then return end

    -- Process output into lines
    local lines = {}
    table.insert(lines, "Dotfiles Status:")
    table.insert(lines, "----------------")
    table.insert(lines, "")

    -- Add helpful commands
    table.insert(lines, "Commands:")
    table.insert(lines, "  a: Stage file under cursor")
    table.insert(lines, "  A: Stage all files")
    table.insert(lines, "  c: Commit staged changes")
    table.insert(lines, "  p: Push changes")
    table.insert(lines, "  r: Refresh status")
    table.insert(lines, "  q: Close this buffer")
    table.insert(lines, "")

    -- Add status output
    for line in output:gmatch("[^\r\n]+") do
        -- Colorize the output by adding special characters
        if line:match("^%s*modified:") then
            line = "  M " .. line:match("modified:%s*(.+)")
        elseif line:match("^%s*new file:") then
            line = "  A " .. line:match("new file:%s*(.+)")
        elseif line:match("^%s*deleted:") then
            line = "  D " .. line:match("deleted:%s*(.+)")
        end

        table.insert(lines, line)
    end

    -- Create or get buffer and populate it
    local bufnr = M.get_buffer("Status")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add buffer-specific keymaps for actions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "a",
        [[<cmd>lua require('datakai.utils.dotfiles').add_file_under_cursor()<CR>]],
        { noremap = true, silent = true, desc = "Stage file under cursor" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "A", [[<cmd>lua require('datakai.utils.dotfiles').add_all()<CR>]],
        { noremap = true, silent = true, desc = "Stage all files" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "c", [[<cmd>lua require('datakai.utils.dotfiles').commit()<CR>]],
        { noremap = true, silent = true, desc = "Commit changes" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "p", [[<cmd>lua require('datakai.utils.dotfiles').push()<CR>]],
        { noremap = true, silent = true, desc = "Push changes" })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "r", [[<cmd>lua require('datakai.utils.dotfiles').status()<CR>]],
        { noremap = true, silent = true, desc = "Refresh status" })

    -- Focus buffer if not already focused
    if vim.api.nvim_get_current_buf() ~= bufnr then
        vim.cmd("buffer " .. bufnr)
    end
end

-- Extract filename from status line under cursor
M.add_file_under_cursor = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(bufnr)

    -- Only work in status buffer
    if not buf_name:match("Dotfiles Status$") then
        vim.notify("Not in dotfiles status buffer", vim.log.levels.ERROR)
        return
    end

    -- Get line under cursor
    local line_nr = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_buf_get_lines(bufnr, line_nr - 1, line_nr, false)[1]

    -- Extract filename - look for modified files
    local file_path

    -- Check for modified files (lines starting with M)
    if line:match("^%s*M%s+") then
        file_path = line:gsub("^%s*M%s+", "")
    elseif line:match("^%s*A%s+") then
        file_path = line:gsub("^%s*A%s+", "")
    elseif line:match("^%s*D%s+") then
        file_path = line:gsub("^%s*D%s+", "")
    end

    if not file_path then
        vim.notify("No file found under cursor", vim.log.levels.WARN)
        return
    end

    M.add_file(file_path)

    -- Refresh the status buffer
    vim.schedule(function()
        M.status()
    end)
end

-- Add the current file to dotfiles
M.add_current = function()
    local file_path = vim.fn.expand("%:p")

    -- Convert absolute path to path relative to $HOME
    local home_pattern
    if platform.os == "windows" then
        -- Windows: handle both forward and backslashes
        home_pattern = "^" .. platform.get_home():gsub("\\", "\\\\") .. "[/\\]?"
    else
        -- Unix: just handle forward slashes
        home_pattern = "^" .. platform.get_home() .. "/?"
    end

    if file_path:match(home_pattern) then
        file_path = file_path:gsub(home_pattern, "")
    end

    local output = M.run_cmd("add " .. vim.fn.shellescape(file_path))
    if output ~= "" then
        vim.notify(output, vim.log.levels.WARN)
    else
        vim.notify("Added " .. file_path .. " to dotfiles", vim.log.levels.INFO)
    end
end

-- Add a specific file to dotfiles
M.add_file = function(file_path)
    if not file_path or file_path == "" then
        vim.notify("No file specified", vim.log.levels.WARN)
        return false
    end

    -- Convert absolute path to path relative to $HOME
    local home_pattern
    if platform.os == "windows" then
        -- Windows: handle both forward and backslashes
        home_pattern = "^" .. platform.get_home():gsub("\\", "\\\\") .. "[/\\]?"
    else
        -- Unix: just handle forward slashes
        home_pattern = "^" .. platform.get_home() .. "/?"
    end

    if file_path:match(home_pattern) then
        file_path = file_path:gsub(home_pattern, "")
    end

    local output = M.run_cmd("add " .. vim.fn.shellescape(file_path))

    if output == "" then -- Empty output means success in your original code
        vim.notify("Added " .. file_path .. " to dotfiles", vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to add " .. file_path .. "\n" .. output, vim.log.levels.ERROR)
        return false
    end
end

-- Add all changes to dotfiles
M.add_all = function()
    local output, exit_code = M.run_cmd("add -A")

    if exit_code == 0 then
        vim.notify("Added all changed files to dotfiles", vim.log.levels.INFO)

        -- Refresh the status if we're in the status buffer
        local bufnr = vim.api.nvim_get_current_buf()
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if buf_name:match(M.config.buffer_name .. " Status$") then
            vim.schedule(function()
                M.status()
            end)
        end

        return true
    else
        vim.notify("Failed to add all files\n" .. output, vim.log.levels.ERROR)
        return false
    end
end

-- Remove a file from dotfiles tracking
M.remove_file = function(file_path)
    if not file_path or file_path == "" then
        file_path = vim.fn.input("File to remove: ")
    end

    if file_path == "" then
        vim.notify("No file specified", vim.log.levels.WARN)
        return false
    end

    local output = M.run_cmd("rm " .. vim.fn.shellescape(file_path))
    if output ~= "" then
        vim.notify(output, vim.log.levels.WARN)
    else
        vim.notify("Removed " .. file_path .. " from dotfiles", vim.log.levels.INFO)
    end
end

-- Commit changes
M.commit = function()
    local message = vim.fn.input({
        prompt = "Commit message: ",
        completion = "file",
    })

    if message == "" then
        vim.notify("Commit aborted: No message provided", vim.log.levels.WARN)
        return false
    end

    local output, exit_code = M.run_cmd('commit -m ' .. vim.fn.shellescape(message))

    if exit_code == 0 then
        vim.notify("Changes committed successfully", vim.log.levels.INFO)

        -- Refresh the status if we're in the status buffer
        local bufnr = vim.api.nvim_get_current_buf()
        local buf_name = vim.api.nvim_buf_get_name(bufnr)
        if buf_name:match(M.config.buffer_name .. " Status$") then
            vim.schedule(function()
                M.status()
            end)
        end

        return true
    else
        vim.notify("Commit failed\n" .. output, vim.log.levels.ERROR)
        return false
    end
end

-- Push changes with ssh (cross-platform)
M.push = function()
    -- Set up SSH command with specific key
    local ssh_command

    if platform.os == "windows" then
        -- Windows might not support GIT_SSH_COMMAND the same way
        ssh_command = string.format('set "GIT_SSH_COMMAND=ssh -i %s" &&', vim.fn.shellescape(M.config.ssh_key))
    else
        -- Unix systems
        ssh_command = string.format("GIT_SSH_COMMAND='ssh -i %s'", M.config.ssh_key)
    end

    local cmd = ssh_command .. " " .. M.base_cmd .. " push"

    -- Create a terminal buffer for the push operation
    vim.cmd("new")
    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")

    -- Set buffer properties
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(bufnr, M.config.buffer_name .. " Push")

    -- Add keymaps for closing the terminal when done
    vim.api.nvim_buf_set_keymap(bufnr, "t", "<ESC>", [[<C-\><C-n>:bd!<CR>]],
        { noremap = true, silent = true })

    vim.notify("Pushing dotfiles changes with SSH key: " .. M.config.ssh_key, vim.log.levels.INFO)
end

-- Pull changes with ssh (cross-platform)
M.pull = function()
    -- Set up SSH command with specific key
    local ssh_command

    if platform.os == "windows" then
        -- Windows might not support GIT_SSH_COMMAND the same way
        ssh_command = string.format('set "GIT_SSH_COMMAND=ssh -i %s" &&', vim.fn.shellescape(M.config.ssh_key))
    else
        -- Unix systems
        ssh_command = string.format("GIT_SSH_COMMAND='ssh -i %s'", M.config.ssh_key)
    end

    local cmd = ssh_command .. " " .. M.base_cmd .. " pull"

    -- Create a terminal buffer for the pull operation
    vim.cmd("new")
    vim.cmd("terminal " .. cmd)
    vim.cmd("startinsert")

    -- Set buffer properties
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(bufnr, M.config.buffer_name .. " Pull")

    -- Add keymaps for closing the terminal when done
    vim.api.nvim_buf_set_keymap(bufnr, "t", "<ESC>", [[<C-\><C-n>:bd!<CR>]],
        { noremap = true, silent = true })

    vim.notify("Pulling dotfiles changes with SSH key: " .. M.config.ssh_key, vim.log.levels.INFO)
end

-- Show a log of recent commits
M.log = function()
    local output, code = M.run_cmd("log --oneline -n 20")
    if code ~= 0 then return end

    local lines = {}
    table.insert(lines, "Dotfiles Recent Commits:")
    table.insert(lines, "------------------------")
    table.insert(lines, "")

    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local bufnr = M.get_buffer("Log")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add buffer-specific keymaps for actions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true, desc = "Close buffer" })

    if vim.api.nvim_get_current_buf() ~= bufnr then
        vim.cmd("buffer " .. bufnr)
    end
end

-- List all tracked files
M.list_files = function()
    local output, code = M.run_cmd("ls-files")
    if code ~= 0 then return end

    local lines = {}
    table.insert(lines, "Dotfiles Tracked Files:")
    table.insert(lines, "----------------------")
    table.insert(lines, "")

    -- Process and categorize files
    local files_by_dir = {}
    local total_count = 0

    for line in output:gmatch("[^\r\n]+") do
        total_count = total_count + 1

        -- Get directory path - account for both slash types
        local dir = line:match("^(.+)[/\\][^/\\]+$") or "root"

        -- Initialize directory entry if needed
        if not files_by_dir[dir] then
            files_by_dir[dir] = {}
        end

        table.insert(files_by_dir[dir], line)
    end

    -- Sort directories
    local dirs = {}
    for dir, _ in pairs(files_by_dir) do
        table.insert(dirs, dir)
    end
    table.sort(dirs)

    -- Add summary
    table.insert(lines, "Total files: " .. total_count)
    table.insert(lines, "")

    -- Add files by directory
    for _, dir in ipairs(dirs) do
        local files = files_by_dir[dir]
        table.insert(lines, dir .. " (" .. #files .. " files):")

        table.sort(files)
        for _, file in ipairs(files) do
            if dir == "root" then
                table.insert(lines, "  " .. file)
            else
                -- Extract just the filename - account for both slash types
                local filename = file:match("^.+[/\\]([^/\\]+)$")
                table.insert(lines, "  " .. filename)
            end
        end

        table.insert(lines, "")
    end

    local bufnr = M.get_buffer("Files")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add buffer-specific keymaps for actions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true, desc = "Close buffer" })

    if vim.api.nvim_get_current_buf() ~= bufnr then
        vim.cmd("buffer " .. bufnr)
    end
end

-- Initialize new dotfiles repository
M.init_repo = function()
    -- Check if dotfiles already exists
    if vim.fn.isdirectory(M.config.git_dir) == 1 then
        vim.notify("Dotfiles repository already exists at " .. M.config.git_dir, vim.log.levels.WARN)
        if vim.fn.confirm("Reinitialize dotfiles repository?", "&Yes\n&No") ~= 1 then
            return
        end
    end

    -- Create the git directory
    platform.ensure_directory(M.config.git_dir)

    -- Initialize bare repository
    local cmd = string.format("git init --bare %s", vim.fn.shellescape(M.config.git_dir))
    local output, exit_code = platform.system(cmd)

    if exit_code ~= 0 then
        vim.notify("Failed to initialize repository:\n" .. output, vim.log.levels.ERROR)
        return
    end

    -- Set initial configuration
    local configs = {
        string.format([[git --git-dir=%s --work-tree=%s config status.showUntrackedFiles no]],
            vim.fn.shellescape(M.config.git_dir), vim.fn.shellescape(M.config.work_tree)),
        string.format([[git --git-dir=%s --work-tree=%s config user.name "%s"]],
            vim.fn.shellescape(M.config.git_dir), vim.fn.shellescape(M.config.work_tree),
            vim.fn.input("Enter your name for dotfiles: ")),
        string.format([[git --git-dir=%s --work-tree=%s config user.email "%s"]],
            vim.fn.shellescape(M.config.git_dir), vim.fn.shellescape(M.config.work_tree),
            vim.fn.input("Enter your email for dotfiles: "))
    }

    -- Apply configurations
    for _, config_cmd in ipairs(configs) do
        platform.system(config_cmd)
    end

    -- Create gitignore to prevent recursion problems
    local gitignore_path = platform.normalize_path(M.config.work_tree .. "/.gitignore")
    local gitignore_content = {
        ".dotfiles",
        ".git",
        -- Common paths to exclude
        "node_modules/",
        "*/node_modules/",
        ".DS_Store",
        "Thumbs.db",
        -- Sensitive directories
        ".ssh/",
        ".aws/",
        ".gnupg/",
    }

    -- Write gitignore
    local file = io.open(gitignore_path, "w")
    if file then
        file:write(table.concat(gitignore_content, "\n"))
        file:close()

        -- Add gitignore to dotfiles
        M.run_cmd("add " .. vim.fn.shellescape(".gitignore"))
        M.run_cmd("commit -m \"Initial commit with .gitignore\"")
    end

    -- Success notification
    vim.notify("Dotfiles repository initialized successfully at " .. M.config.git_dir, vim.log.levels.INFO)

    -- Ask about adding a remote
    if vim.fn.confirm("Would you like to add a remote repository?", "&Yes\n&No") == 1 then
        local remote_url = vim.fn.input("Enter remote URL: ")
        if remote_url ~= "" then
            local remote_cmd = string.format([[git --git-dir=%s --work-tree=%s remote add %s %s]],
                vim.fn.shellescape(M.config.git_dir),
                vim.fn.shellescape(M.config.work_tree),
                M.config.default_remote,
                vim.fn.shellescape(remote_url))

            platform.system(remote_cmd)
            vim.notify("Remote added: " .. remote_url, vim.log.levels.INFO)
        end
    end
end



-- Add common dotfiles from templates based on detected OS
M.add_common_files = function()
    -- Define template files based on OS
    local templates = {}

    -- Common files for all platforms
    local common = {
        ".gitconfig",
        ".vimrc",
        ".tmux.conf"
    }

    -- OS-specific files
    if platform.os == "macos" then
        templates = {
            ".zshrc",
            ".zprofile",
            ".bash_profile",
            ".config/wezterm/wezterm.lua"
        }
    elseif platform.os == "linux" then
        templates = {
            ".bashrc",
            ".bash_profile",
            ".config/wezterm/wezterm.lua"
        }
    elseif platform.os == "wsl" then
        templates = {
            ".bashrc",
            ".zshrc",
            ".config/wezterm/wezterm.lua"
        }
    elseif platform.os == "windows" then
        templates = {
            ".config/wezterm/wezterm.lua"
        }
    end

    -- Add common files to templates
    for _, file in ipairs(common) do
        table.insert(templates, file)
    end

    -- Show selection menu for files
    vim.ui.select(templates, {
        prompt = "Select files to add to dotfiles:",
        format_item = function(item) return item end,
        kind = "multi-select"
    }, function(selected_files)
        if selected_files and #selected_files > 0 then
            -- Add each selected file
            for _, file in ipairs(selected_files) do
                local file_path = platform.normalize_path(platform.get_home() .. "/" .. file)

                -- Check if file exists
                if vim.fn.filereadable(file_path) == 1 then
                    M.add_file(file)
                else
                    vim.notify("File not found: " .. file, vim.log.levels.WARN)
                end
            end

            -- Ask to commit
            if vim.fn.confirm("Commit these files?", "&Yes\n&No") == 1 then
                local message = vim.fn.input("Commit message: ", "Add common dotfiles")
                if message ~= "" then
                    M.run_cmd('commit -m ' .. vim.fn.shellescape(message))
                    vim.notify("Files committed successfully", vim.log.levels.INFO)
                end
            end
        end
    end)
end

-- Sync dotfiles between systems (pull then push)
M.sync = function()
    -- Pull changes first
    local pull_cmd

    if platform.os == "windows" then
        -- Windows might not support GIT_SSH_COMMAND the same way
        pull_cmd = string.format('set "GIT_SSH_COMMAND=ssh -i %s" && %s pull',
            vim.fn.shellescape(M.config.ssh_key), M.base_cmd)
    else
        -- Unix systems
        pull_cmd = string.format("GIT_SSH_COMMAND='ssh -i %s' %s pull",
            M.config.ssh_key, M.base_cmd)
    end

    -- Start sync by pulling
    vim.notify("Syncing dotfiles - pulling changes...", vim.log.levels.INFO)
    local pull_output, pull_exit = platform.system(pull_cmd)

    if pull_exit ~= 0 then
        vim.notify("Failed to pull changes:\n" .. pull_output, vim.log.levels.ERROR)
    else
        vim.notify("Pull successful, now pushing any local changes...", vim.log.levels.INFO)

        -- Then push any local changes
        local push_cmd

        if platform.os == "windows" then
            push_cmd = string.format('set "GIT_SSH_COMMAND=ssh -i %s" && %s push',
                vim.fn.shellescape(M.config.ssh_key), M.base_cmd)
        else
            push_cmd = string.format("GIT_SSH_COMMAND='ssh -i %s' %s push",
                M.config.ssh_key, M.base_cmd)
        end

        local push_output, push_exit = platform.system(push_cmd)

        if push_exit ~= 0 then
            vim.notify("Failed to push changes:\n" .. push_output, vim.log.levels.ERROR)
        else
            vim.notify("Dotfiles successfully synchronized", vim.log.levels.INFO)
        end
    end
end

-- Open dotfiles directory in file browser
M.browse = function()
    if platform.os == "macos" then
        platform.system("open " .. vim.fn.shellescape(M.config.work_tree))
    elseif platform.os == "windows" then
        platform.system("explorer " .. vim.fn.shellescape(M.config.work_tree))
    elseif platform.os == "wsl" then
        platform.system("explorer.exe " .. vim.fn.shellescape(M.config.work_tree))
    else
        -- Linux
        local file_managers = { "xdg-open", "nautilus", "dolphin", "thunar", "pcmanfm" }

        for _, manager in ipairs(file_managers) do
            if platform.command_exists(manager) then
                platform.system(manager .. " " .. vim.fn.shellescape(M.config.work_tree))
                return
            end
        end

        vim.notify("No file manager found. Please install one of: nautilus, dolphin, thunar, pcmanfm",
            vim.log.levels.WARN)
    end
end

-- Check for differences between systems
M.diff_check = function()
    -- Get list of tracked files
    local output, code = M.run_cmd("ls-files", true)
    if code ~= 0 then return end

    local tracked_files = {}
    for file in output:gmatch("[^\r\n]+") do
        tracked_files[file] = true
    end

    -- Check each file
    local missing_files = {}
    local modified_files = {}

    for file, _ in pairs(tracked_files) do
        local file_path = platform.normalize_path(M.config.work_tree .. "/" .. file)

        -- Check if file exists
        if vim.fn.filereadable(file_path) ~= 1 then
            table.insert(missing_files, file)
        else
            -- Check if file differs from repository
            local diff_output, _ = M.run_cmd("diff --name-only " .. vim.fn.shellescape(file), true)
            if diff_output ~= "" then
                table.insert(modified_files, file)
            end
        end
    end

    -- Display results
    local lines = {
        "Dotfiles System Difference Check:",
        "--------------------------------",
        ""
    }

    if #missing_files > 0 then
        table.insert(lines, "Missing Files:")
        for _, file in ipairs(missing_files) do
            table.insert(lines, "  " .. file)
        end
        table.insert(lines, "")
    end

    if #modified_files > 0 then
        table.insert(lines, "Modified Files:")
        for _, file in ipairs(modified_files) do
            table.insert(lines, "  " .. file)
        end
        table.insert(lines, "")
    end

    if #missing_files == 0 and #modified_files == 0 then
        table.insert(lines, "No differences found between this system and the dotfiles repository.")
    end

    -- Display in buffer
    local bufnr = M.get_buffer("Diff Check")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Add keymaps
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", ":bdelete<CR>",
        { noremap = true, silent = true, desc = "Close buffer" })

    if vim.api.nvim_get_current_buf() ~= bufnr then
        vim.cmd("buffer " .. bufnr)
    end
end

-- Initialize the module with defaults
M.setup()

return M
