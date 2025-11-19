-- Core Account Management Module for git_account
-- Handles account storage, retrieval, and configuration

local M = {}

-- Import cross-platform utilities
local platform = require('datakai.utils.platform')
local ssh_module = require('datakai.utils.git_account.ssh')

-- Default configuration with platform-aware paths
M.config = {
    accounts_file = platform.normalize_path(platform.get_home() .. "/.config/nvim/git_accounts.lua"),
    ssh_config_path = platform.normalize_path(platform.get_home() .. "/.ssh/config"),
    templates_dir = platform.normalize_path(platform.get_home() .. "/.config/git/templates"),
    hooks_dir = platform.normalize_path(platform.get_home() .. "/.config/git/hooks")
}

-- Empty accounts table - will be populated from accounts file if it exists
M.accounts = {}

-- SSH hosts cache
M.ssh_hosts = {}

-- Initialize the module with custom config
M.setup = function(opts)
    opts = opts or {}

    -- Apply any provided configuration
    for k, v in pairs(opts) do
        M.config[k] = v
    end

    -- Parse SSH config first
    M.ssh_hosts = ssh_module.parse_ssh_config(M.config.ssh_config_path)

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

-- Reload SSH configuration
M.reload_ssh_config = function()
    M.ssh_hosts = ssh_module.parse_ssh_config(M.config.ssh_config_path)

    -- Update account SSH information
    for name, account in pairs(M.accounts) do
        if account.ssh_host and M.ssh_hosts[account.ssh_host] then
            account.ssh_key = M.ssh_hosts[account.ssh_host].identity_file
            account.ssh_user = M.ssh_hosts[account.ssh_host].user
        end
    end
end

-- Get current git identity
M.get_current_identity = function()
    local git_ops = require('datakai.utils.git_account.git_ops')
    local name, name_exit = git_ops.run_git_cmd("config user.name", true)
    local email, email_exit = git_ops.run_git_cmd("config user.email", true)

    if name_exit ~= 0 or email_exit ~= 0 then
        return nil
    end

    return {
        name = name:gsub("\n", ""),
        email = email:gsub("\n", "")
    }
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
        -- Use platform-specific directory creation
        platform.ensure_directory(dir)
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

    local git_ops = require('datakai.utils.git_account.git_ops')
    if git_ops.in_git_repo() then
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

return M
