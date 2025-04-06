-- dotfiles.lua - Enhanced dotfiles management module
-- Manages dotfiles in a bare git repository approach

local M = {}

-- Configuration settings with defaults
M.config = {
    git_dir = os.getenv("HOME") .. "/.dotfiles",
    work_tree = os.getenv("HOME"),
    ssh_key = os.getenv("HOME") .. "/.ssh/git_datakaicr",
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
    local output = vim.fn.system(full_cmd)
    local exit_code = vim.v.shell_error

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
    local home = os.getenv("HOME")

    -- Convert absolute path to path relative to $HOME
    if file_path:sub(1, #home) == home then
        file_path = file_path:sub(#home + 2) -- +2 to skip the / after HOME
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
    local home = os.getenv("HOME")
    if file_path:sub(1, #home) == home then
        file_path = file_path:sub(#home + 2) -- +2 to skip the / after HOME
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
    local output, exit_code = M.run_cmd("add -u")

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

-- Push changes with ssh
M.push = function()
    -- Set up SSH command with specific key
    local ssh_command = "GIT_SSH_COMMAND='ssh -i " .. M.config.ssh_key .. "'"
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

-- Pull changes with ssh
M.pull = function()
    -- Set up SSH command with specific key
    local ssh_command = "GIT_SSH_COMMAND='ssh -i " .. M.config.ssh_key .. "'"
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

        -- Get directory path
        local dir = line:match("^(.+)/[^/]+$") or "root"

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
                -- Extract just the filename
                local filename = file:match("^.+/([^/]+)$")
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

-- Initialize the module with defaults
M.setup()

return M
