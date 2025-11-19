-- Tmux Sessionizer integration for Neovim
local M = {}

-- Call tmux-sessionizer script
M.sessionizer = function()
    -- Run the sessionizer in a tmux popup
    vim.fn.system('tmux display-popup -E ~/.local/bin/tmux-sessionizer')
end

-- Switch to company workspace
M.workspace = function()
    vim.fn.system('tmux display-popup -E ~/.local/bin/tmux-workspace')
end

-- Get current tmux session name
M.get_session = function()
    local handle = io.popen('tmux display-message -p "#S"')
    if handle then
        local session = handle:read('*a')
        handle:close()
        return session:gsub('%s+', '')
    end
    return nil
end

-- Auto-set git config based on project directory and .project.toml metadata
M.auto_git_config = function()
    local cwd = vim.fn.getcwd()
    local config = require("datakai.config")

    -- First, try to read .project.toml for git account info
    local project_file = cwd .. "/.project.toml"
    if vim.fn.filereadable(project_file) == 1 then
        local handle = io.open(project_file, "r")
        if handle then
            local owner = nil
            for line in handle:lines() do
                -- Look for primary = "accountname"
                owner = line:match('^primary%s*=%s*"(.-)"')
                if owner then break end
            end
            handle:close()

            if owner then
                -- Try to load git accounts and set config
                local git_account = require("datakai.utils.git_account")
                if git_account.accounts[owner] then
                    -- Use the git_account module's switch function
                    local acc = git_account.accounts[owner]
                    vim.fn.system(string.format('git config user.name "%s"', acc.name))
                    vim.fn.system(string.format('git config user.email "%s"', acc.email))
                    if acc.ssh_host then
                        git_account.configure_git_ssh(acc)
                    end
                    vim.notify('Git config set to: ' .. owner .. ' (from .project.toml)', vim.log.levels.INFO)
                    return
                end
            end
        end
    end

    -- Fallback: Check if we're in known directories using config
    local default_account = nil
    if cwd:find(config.workspace.scriptorium_dir, 1, true) then
        default_account = "datakai"
    elseif cwd:find(config.workspace.projects_dir, 1, true) then
        -- Default to datakai for projects directory
        default_account = "datakai"
    end

    if default_account then
        local git_account = require("datakai.utils.git_account")
        if git_account.accounts[default_account] then
            local acc = git_account.accounts[default_account]
            vim.fn.system(string.format('git config user.name "%s"', acc.name))
            vim.fn.system(string.format('git config user.email "%s"', acc.email))
            vim.notify('Git config set to: ' .. default_account .. ' (default)', vim.log.levels.INFO)
        end
    end
end

-- Setup keymaps
M.setup = function()
    -- Tmux sessionizer
    vim.keymap.set('n', '<C-f>', M.sessionizer, {
        desc = 'Tmux Sessionizer',
        silent = true
    })

    -- Company workspace switcher
    vim.keymap.set('n', '<leader>tw', M.workspace, {
        desc = 'Tmux Workspace Switcher',
        silent = true
    })

    -- Auto-configure git on directory change
    vim.api.nvim_create_autocmd('DirChanged', {
        callback = M.auto_git_config,
        desc = 'Auto-configure git based on directory',
    })

    -- Also run on VimEnter
    vim.api.nvim_create_autocmd('VimEnter', {
        callback = M.auto_git_config,
        desc = 'Auto-configure git on startup',
    })
end

return M
