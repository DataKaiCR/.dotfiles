local M = {}

-- Base dotfiles command
M.dotfiles_cmd = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
M.ssh_key = "~/.ssh/git_datakaicr" -- Set your dotfiles SSH key here

-- Run a dotfiles command
M.run_cmd = function(cmd)
    local full_cmd = M.dotfiles_cmd .. " " .. cmd
    local output = vim.fn.system(full_cmd)
    return output
end

-- Show dotfiles status
M.status = function()
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, "Dotfiles Status")

    -- Get status
    local output = M.run_cmd("status")
    local lines = {}
    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Add header
    table.insert(lines, 1, "Dotfiles Status:")
    table.insert(lines, 2, "----------------")
    table.insert(lines, 3, "")

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

-- Add the current file to dotfiles
M.add_current = function()
    local file_path = vim.fn.expand("%:p")
    local output = M.run_cmd("add " .. file_path)
    if output ~= "" then
        vim.notify(output, vim.log.levels.WARN)
    else
        vim.notify("Added " .. file_path .. " to dotfiles", vim.log.levels.INFO)
    end
end

-- Add all changes to dotfiles
M.add_all = function()
    local output = M.run_cmd("add -u")
    if output ~= "" then
        vim.notify(output, vim.log.levels.WARN)
    else
        vim.notify("Added all changed files to dotfiles", vim.log.levels.INFO)
    end
end

-- Commit changes
M.commit = function()
    local message = vim.fn.input("Commit message: ")
    if message == "" then
        vim.notify("Commit aborted: No message provided", vim.log.levels.WARN)
        return
    end

    local output = M.run_cmd("commit -m \"" .. message .. "\"")
    vim.notify(output, vim.log.levels.INFO)
end

-- Push changes with ssh
M.push = function()
    -- Set the specific SSH key for dotfiles
    local ssh_command = "GIT_SSH_COMMAND='ssh -i " .. M.ssh_key .. "' "

    -- Use a terminal buffer with the SSH command
    vim.cmd("terminal " .. ssh_command .. M.dotfiles_cmd .. " push")

    -- Enter insert mode for interaction
    vim.cmd("startinsert")

    vim.notify("Running dotfiles push with personal SSH key", vim.log.levels.INFO)
end

-- List all tracked files
M.list_files = function()
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
    vim.api.nvim_buf_set_name(bufnr, "Dotfiles Tracked Files")

    -- Get list of tracked files
    local output = M.run_cmd("ls-files")
    local lines = {}
    for line in output:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    -- Add header
    table.insert(lines, 1, "Dotfiles Tracked Files:")
    table.insert(lines, 2, "----------------------")
    table.insert(lines, 3, "")

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
