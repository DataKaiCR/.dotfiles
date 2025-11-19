-- config.lua - Centralized configuration for datakai nvim setup
-- This module provides a single source of truth for paths, directories, and settings
-- used across the entire Neovim configuration.

local M = {}
local platform = require('datakai.utils.platform')

-- ============================================================================
-- CORE PATHS
-- ============================================================================

M.paths = {
    -- Home directory (cross-platform)
    home = platform.get_home(),

    -- Neovim config directory
    nvim_config = vim.fn.stdpath('config'),

    -- Neovim data directory
    nvim_data = vim.fn.stdpath('data'),
}

-- ============================================================================
-- PROJECT & WORKSPACE PATHS
-- ============================================================================

M.workspace = {
    -- Main projects directory
    projects_dir = platform.normalize_path(M.paths.home .. "/projects"),

    -- Archive directory for completed projects
    archive_dir = platform.normalize_path(M.paths.home .. "/archive"),

    -- Scriptorium (knowledge management/notes)
    scriptorium_dir = platform.normalize_path(M.paths.home .. "/scriptorium"),

    -- Additional workspace directories (can be customized)
    workspace_dir = platform.normalize_path(M.paths.home .. "/workspace"),
    resources_dir = platform.normalize_path(M.paths.home .. "/resources"),
}

-- ============================================================================
-- KNOWLEDGE MANAGEMENT (Obsidian/Zettelkasten)
-- ============================================================================

M.knowledge = {
    -- Main vault location
    vault_path = M.workspace.scriptorium_dir,
    vault_name = "scriptorium",

    -- Obsidian folder structure (PARA + Zettelkasten hybrid)
    folders = {
        inbox = "00-inbox",
        journal = "00-journal",
        daily = "00-journal/daily",
        weekly = "00-journal/weekly",
        projects = "01-projects",
        areas = "02-areas",
        resources = "03-resources",
        archive = "04-archive",
        templates = "_templates",
        assets = "_assets",
    },

    -- Asset subfolders
    assets = {
        images = "_assets/images",
        excalidraw = "_assets/excalidraw",
        input = "_assets/input",
        output = "_assets/output",
    },

    -- Template settings
    templates = {
        subdir = "_templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M:%S%z",
    },
}

-- ============================================================================
-- GIT CONFIGURATION
-- ============================================================================

M.git = {
    -- Git accounts configuration file
    accounts_file = platform.normalize_path(M.paths.nvim_config .. "/git_accounts.lua"),

    -- Git templates and hooks
    templates_dir = platform.normalize_path(M.paths.home .. "/.config/git/templates"),
    hooks_dir = platform.normalize_path(M.paths.home .. "/.config/git/hooks"),

    -- Git identity presets (can be overridden by git_accounts.lua)
    default_identities = {
        datakai = {
            name = "datakai",
            ssh_host = "github.com-datakaicr",
        },
        westmonroe = {
            name = "westmonroe",
            ssh_host = "github.com-westmonroe",
        },
    },
}

-- ============================================================================
-- SSH CONFIGURATION
-- ============================================================================

M.ssh = {
    -- SSH config file
    config_path = platform.normalize_path(M.paths.home .. "/.ssh/config"),

    -- SSH keys directory
    keys_dir = platform.normalize_path(M.paths.home .. "/.ssh"),
}

-- ============================================================================
-- TMUX INTEGRATION
-- ============================================================================

M.tmux = {
    -- Tmux configuration directory
    config_dir = platform.normalize_path(M.paths.home .. "/.config/tmux"),

    -- Tmux plugins directory
    plugins_dir = platform.normalize_path(M.paths.home .. "/.config/tmux/plugins"),

    -- Project search paths for tmux sessionizer
    search_paths = {
        M.workspace.projects_dir,
        M.workspace.archive_dir,
        M.workspace.scriptorium_dir,
    },
}

-- ============================================================================
-- DOTFILES MANAGEMENT
-- ============================================================================

M.dotfiles = {
    -- Bare git repository location
    repo_dir = platform.normalize_path(M.paths.home .. "/.dotfiles"),

    -- Work tree (home directory)
    work_tree = M.paths.home,

    -- Exclude file
    exclude_file = platform.normalize_path(M.paths.home .. "/.dotfiles/info/exclude"),
}

-- ============================================================================
-- PYTHON DEVELOPMENT
-- ============================================================================

M.python = {
    -- Virtual environment locations
    venv_patterns = {
        ".venv",
        "venv",
        ".virtualenv",
        "virtualenv",
        "env",
    },

    -- Python LSP
    lsp_server = "basedpyright",  -- or "pyright", "pylsp"

    -- Formatter
    formatter = "ruff",  -- or "black", "autopep8"

    -- Linter
    linter = "ruff",  -- or "flake8", "pylint"
}

-- ============================================================================
-- DOCKER DEVELOPMENT
-- ============================================================================

M.docker = {
    -- Default devcontainer settings
    default_container_prefix = "devcontainer",

    -- Docker compose file patterns
    compose_files = {
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml",
    },
}

-- ============================================================================
-- CLOUD INTEGRATIONS (for Phase 3)
-- ============================================================================

M.cloud = {
    -- AWS
    aws = {
        config_dir = platform.normalize_path(M.paths.home .. "/.aws"),
        profile_env = "AWS_PROFILE",
    },

    -- Databricks
    databricks = {
        config_file = platform.normalize_path(M.paths.home .. "/.databrickscfg"),
    },

    -- Terraform
    terraform = {
        plugin_cache = platform.normalize_path(M.paths.home .. "/.terraform.d/plugin-cache"),
    },
}

-- ============================================================================
-- UI/UX SETTINGS
-- ============================================================================

M.ui = {
    -- Border style for floating windows
    border = "rounded",  -- "single", "double", "rounded", "solid", "shadow"

    -- Transparency
    transparency = false,

    -- Conceal level for markdown
    conceallevel = 2,

    -- Icons
    use_icons = true,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Get full path to a project
M.get_project_path = function(project_name)
    local active = platform.normalize_path(M.workspace.projects_dir .. "/" .. project_name)
    local archived = platform.normalize_path(M.workspace.archive_dir .. "/" .. project_name)

    if vim.fn.isdirectory(active) == 1 then
        return active
    elseif vim.fn.isdirectory(archived) == 1 then
        return archived
    else
        return nil
    end
end

-- Get full path to a vault folder
M.get_vault_folder_path = function(folder_key)
    if M.knowledge.folders[folder_key] then
        return platform.normalize_path(M.knowledge.vault_path .. "/" .. M.knowledge.folders[folder_key])
    else
        return nil
    end
end

-- Check if a file/directory exists
M.path_exists = function(path)
    return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
end

-- Expand path with ~ to full home path
M.expand_path = function(path)
    if path:sub(1, 1) == "~" then
        return platform.normalize_path(M.paths.home .. path:sub(2))
    end
    return path
end

-- ============================================================================
-- SETUP FUNCTION
-- ============================================================================

-- Allow users to override configuration
M.setup = function(opts)
    opts = opts or {}

    -- Deep merge user config into M
    for category, settings in pairs(opts) do
        if type(M[category]) == "table" and type(settings) == "table" then
            for key, value in pairs(settings) do
                M[category][key] = value
            end
        else
            M[category] = settings
        end
    end

    return M
end

-- ============================================================================
-- VALIDATION (Optional - helps catch config errors early)
-- ============================================================================

M.validate = function()
    local errors = {}

    -- Check critical paths exist
    if vim.fn.isdirectory(M.workspace.projects_dir) ~= 1 then
        table.insert(errors, "Projects directory not found: " .. M.workspace.projects_dir)
    end

    if vim.fn.isdirectory(M.knowledge.vault_path) ~= 1 then
        table.insert(errors, "Vault directory not found: " .. M.knowledge.vault_path)
    end

    -- Report errors
    if #errors > 0 then
        vim.notify("Configuration validation errors:\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
        return false
    end

    return true
end

return M
