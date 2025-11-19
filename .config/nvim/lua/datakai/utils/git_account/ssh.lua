-- SSH Configuration Module for git_account
-- Handles SSH config parsing and management

local M = {}

-- Import cross-platform utilities
local platform = require('datakai.utils.platform')

-- Parse SSH config and extract hosts with their identity files
M.parse_ssh_config = function(ssh_config_path)
    local ssh_hosts = {}
    local current_host = nil

    -- Check if SSH config exists
    if vim.fn.filereadable(vim.fn.expand(ssh_config_path)) ~= 1 then
        return ssh_hosts
    end

    -- Read SSH config file
    local lines = vim.fn.readfile(vim.fn.expand(ssh_config_path))

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
                    -- Replace ~ with home directory and normalize path
                    identity_file = identity_file:gsub("^~", platform.get_home())
                    ssh_hosts[current_host].identity_file = platform.normalize_path(identity_file)
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

-- List all SSH hosts in the config
M.list_ssh_hosts = function(ssh_hosts)
    local lines = {
        "SSH Hosts in Config:",
        "-------------------",
        ""
    }

    -- Sort hosts
    local host_names = {}
    for host, _ in pairs(ssh_hosts) do
        table.insert(host_names, host)
    end
    table.sort(host_names)

    -- Add details for each host
    for _, host in ipairs(host_names) do
        local info = ssh_hosts[host]
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

-- Edit SSH config (opens the config file for editing)
M.edit_ssh_config = function(ssh_config_path, on_reload_callback)
    -- Check if SSH config exists
    local config_path = vim.fn.expand(ssh_config_path)

    -- Create directory if it doesn't exist
    local dir = vim.fn.fnamemodify(config_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        platform.ensure_directory(dir)
    end

    if vim.fn.filereadable(config_path) ~= 1 then
        -- Create empty config if it doesn't exist
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
            if on_reload_callback then
                on_reload_callback()
            end
            vim.notify("SSH config reloaded", vim.log.levels.INFO)
        end,
        once = false
    })

    vim.notify("Editing SSH config. Save to reload configuration.", vim.log.levels.INFO)
end

-- Generate a sample SSH config template
M.generate_ssh_template = function(ssh_config_path)
    local config_path = vim.fn.expand(ssh_config_path)

    -- Check if file already exists
    if vim.fn.filereadable(config_path) == 1 then
        if vim.fn.confirm("SSH config already exists. Overwrite with template?", "&Yes\n&No") ~= 1 then
            return
        end
    end

    -- Create directory if needed
    local dir = vim.fn.fnamemodify(config_path, ":h")
    if vim.fn.isdirectory(dir) == 0 then
        platform.ensure_directory(dir)
    end

    -- Generate template content
    local lines = {
        "# SSH Configuration File",
        "# Generated by git_account.lua",
        "",
        "# Default settings for all hosts",
        "Host *",
        "    ServerAliveInterval 60",
        "    ServerAliveCountMax 30",
        "    AddKeysToAgent yes",
        "    IdentitiesOnly yes",
        "",
        "# Personal GitHub account",
        "Host github.com-personal",
        "    HostName github.com",
        "    User git",
        "    IdentityFile ~/.ssh/id_personal",
        "",
        "# Work GitHub account",
        "Host github.com-work",
        "    HostName github.com",
        "    User git",
        "    IdentityFile ~/.ssh/id_work",
        "",
        "# GitLab account",
        "Host gitlab.com",
        "    IdentityFile ~/.ssh/id_gitlab",
        "",
        "# Example for a custom Git server",
        "Host git.example.com",
        "    User git",
        "    IdentityFile ~/.ssh/id_example",
        "    Port 2222",
        "",
        "# Add your custom hosts below",
        ""
    }

    -- Write to file
    local file = io.open(config_path, "w")
    if file then
        file:write(table.concat(lines, "\n"))
        file:close()
        vim.notify("SSH config template generated at " .. config_path, vim.log.levels.INFO)

        -- Open the file for editing
        vim.cmd("edit " .. vim.fn.fnameescape(config_path))
    else
        vim.notify("Failed to create SSH config template", vim.log.levels.ERROR)
    end
end

-- Configure git with SSH host
M.configure_git_ssh = function(account, ssh_config_path)
    if not account.ssh_host then return false end

    -- Platform-specific SSH configuration
    if platform.os == "windows" then
        -- Windows Git has a different way to configure SSH
        local cmd = string.format("git config core.sshCommand 'ssh -i %s'",
            vim.fn.shellescape(account.ssh_key))
        local exit_code = os.execute(cmd)
        return exit_code == 0
    else
        -- Unix-like systems can use SSH_COMMAND in .git/config
        local cmd = string.format("git config core.sshCommand 'ssh -F %s %s'",
            vim.fn.shellescape(vim.fn.expand(ssh_config_path)),
            account.ssh_host)
        local exit_code = os.execute(cmd)
        return exit_code == 0
    end
end

return M
