-- Enhanced git_account.lua with Cross-Platform Support
-- Manages multiple Git identities across systems
-- Refactored into modular structure

local M = {}

-- Import the three core modules
local core = require('datakai.utils.git_account.core')
local ssh_module = require('datakai.utils.git_account.ssh')
local git_ops = require('datakai.utils.git_account.git_ops')

-- Re-export configuration and data from core module
M.config = core.config
M.accounts = core.accounts
M.ssh_hosts = core.ssh_hosts

-- Re-export setup function from core module
M.setup = function(opts)
    local result = core.setup(opts)
    -- Update references to reflect any changes made during setup
    M.config = core.config
    M.accounts = core.accounts
    M.ssh_hosts = core.ssh_hosts
    return M
end

-- Re-export core account management functions
M.add_account = core.add_account
M.remove_account = core.remove_account
M.save_accounts = core.save_accounts
M.list_accounts = core.list_accounts
M.find_account_by_identity = core.find_account_by_identity
M.get_current_identity = core.get_current_identity

-- Re-export SSH functions
M.parse_ssh_config = function()
    return ssh_module.parse_ssh_config(core.config.ssh_config_path)
end

M.list_ssh_hosts = function()
    return ssh_module.list_ssh_hosts(core.ssh_hosts)
end

M.edit_ssh_config = function()
    return ssh_module.edit_ssh_config(core.config.ssh_config_path, core.reload_ssh_config)
end

M.generate_ssh_template = function()
    return ssh_module.generate_ssh_template(core.config.ssh_config_path)
end

M.configure_git_ssh = function(account)
    return ssh_module.configure_git_ssh(account, core.config.ssh_config_path)
end

-- Re-export git operations functions
M.switch_account = git_ops.switch_account
M.init_repo = git_ops.init_repo
M.create_worktree = git_ops.create_worktree
M.list_worktrees = git_ops.list_worktrees
M.in_git_repo = git_ops.in_git_repo
M.run_git_cmd = git_ops.run_git_cmd

-- Initialize the module with defaults
M.setup()

return M
