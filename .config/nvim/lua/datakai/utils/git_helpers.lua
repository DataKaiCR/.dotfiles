-- git_helpers.lua - Cross-platform Git utilities
-- Enhanced with better OS detection and compatibility

local M = {}

-- Import cross-platform utilities
local platform = require('datakai.utils.platform')

-- List available git branches for completion
M.list_branches = function()
    local branches = {}

    -- Get local branches
    local handle = io.popen("git branch --format='%(refname:short)'")
    if handle then
        for line in handle:lines() do
            table.insert(branches, line)
        end
        handle:close()
    end

    -- Get remote branches
    handle = io.popen("git branch -r --format='%(refname:short)'")
    if handle then
        for line in handle:lines() do
            -- Remove remote/ prefix for nicer display
            local branch = line:gsub("^[^/]+/", "")
            -- Avoid duplicates
            if not vim.tbl_contains(branches, branch) then
                table.insert(branches, branch)
            end
        end
        handle:close()
    end

    return branches
end

-- Check if a file is tracked by git
M.is_file_tracked = function(file_path)
    -- Normalize path for the current OS
    file_path = platform.normalize_path(file_path)

    local cmd = "git ls-files --error-unmatch " .. vim.fn.shellescape(file_path) ..
        (platform.os == "windows" and " >nul 2>nul" or " > /dev/null 2>&1")

    local exit_code = os.execute(cmd)
    return exit_code == 0
end

-- Get file git status
M.get_file_status = function(file_path)
    -- Normalize path for the current OS
    file_path = platform.normalize_path(file_path)

    local cmd = "git status --porcelain " .. vim.fn.shellescape(file_path)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()

    result = result:gsub("\n", "")
    return result:sub(1, 2)
end

-- Get the root of the git repository
M.get_git_root = function()
    local handle = io.popen("git rev-parse --show-toplevel")
    if not handle then return nil end

    local result = handle:read("*a"):gsub("\n", "")
    handle:close()

    if result ~= "" then
        -- Normalize path for the current OS
        return platform.normalize_path(result)
    else
        return nil
    end
end

-- Get current branch name
M.get_current_branch = function()
    local handle = io.popen("git symbolic-ref --short HEAD 2>/dev/null")
    if not handle then return nil end

    local result = handle:read("*a"):gsub("\n", "")
    handle:close()

    return result ~= "" and result or nil
end

-- Check if working tree is clean
M.is_working_tree_clean = function()
    local handle = io.popen("git status --porcelain")
    if not handle then return false end

    local result = handle:read("*a")
    handle:close()

    return result == ""
end

-- Get git config value
M.get_git_config = function(key)
    local handle = io.popen("git config --get " .. key)
    if not handle then return nil end

    local result = handle:read("*a"):gsub("\n", "")
    handle:close()

    return result ~= "" and result or nil
end

-- Set git config value
M.set_git_config = function(key, value, global)
    local scope = global and "--global " or ""
    local cmd = "git config " .. scope .. key .. " " .. vim.fn.shellescape(value)

    local exit_code = os.execute(cmd)
    return exit_code == 0
end

-- Add file to .gitignore
M.add_to_gitignore = function(pattern, root_only)
    local gitignore_path

    if root_only then
        -- Only add to repository root .gitignore
        local root = M.get_git_root()
        if not root then
            vim.notify("Not in a git repository", vim.log.levels.ERROR)
            return false
        end
        gitignore_path = root .. platform.get_separator() .. ".gitignore"
    else
        -- Add to nearest .gitignore (or create one)
        gitignore_path = vim.fn.getcwd() .. platform.get_separator() .. ".gitignore"
    end

    -- Check if pattern already exists
    local exists = false
    local lines = {}

    if vim.fn.filereadable(gitignore_path) == 1 then
        lines = vim.fn.readfile(gitignore_path)
        for _, line in ipairs(lines) do
            if line == pattern then
                exists = true
                break
            end
        end
    end

    -- Add pattern if it doesn't exist
    if not exists then
        table.insert(lines, pattern)
        vim.fn.writefile(lines, gitignore_path)
        vim.notify("Added '" .. pattern .. "' to .gitignore", vim.log.levels.INFO)
        return true
    else
        vim.notify("'" .. pattern .. "' already in .gitignore", vim.log.levels.INFO)
        return false
    end
end

-- Create a new git hook
M.create_git_hook = function(hook_name, content)
    local root = M.get_git_root()
    if not root then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return false
    end

    local hook_path = root ..
    platform.get_separator() .. ".git" .. platform.get_separator() .. "hooks" .. platform.get_separator() .. hook_name

    -- Create hooks directory if needed
    local hooks_dir = root .. platform.get_separator() .. ".git" .. platform.get_separator() .. "hooks"
    platform.ensure_directory(hooks_dir)

    -- Write hook file
    local file = io.open(hook_path, "w")
    if file then
        -- Use appropriate shebang depending on platform
        if platform.os == "windows" then
            -- Windows might need a different approach
            file:write("#!/usr/bin/env sh\n\n")
        else
            -- Unix-like systems
            file:write("#!/bin/sh\n\n")
        end

        file:write(content)
        file:close()

        -- Make executable
        if platform.os ~= "windows" then
            os.execute("chmod +x " .. vim.fn.shellescape(hook_path))
        end

        vim.notify("Created git hook: " .. hook_name, vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to create git hook: " .. hook_name, vim.log.levels.ERROR)
        return false
    end
end

-- Setup global gitconfig (cross-platform)
M.setup_global_config = function()
    -- Get user info
    local username = vim.fn.input("Git username: ")
    if username == "" then return end

    local email = vim.fn.input("Git email: ")
    if email == "" then return end

    -- Set global config
    M.set_git_config("user.name", username, true)
    M.set_git_config("user.email", email, true)

    -- Set default init branch
    M.set_git_config("init.defaultBranch", "main", true)

    -- Configure cross-platform line endings
    if platform.os == "windows" then
        -- Windows specific
        M.set_git_config("core.autocrlf", "true", true)
    else
        -- Unix systems
        M.set_git_config("core.autocrlf", "input", true)
    end

    -- Configure editor to be neovim
    local editor_cmd
    if platform.os == "windows" then
        -- Use nvim.exe on Windows
        editor_cmd = "nvim.exe"
    else
        -- Use nvim on Unix systems
        editor_cmd = "nvim"
    end
    M.set_git_config("core.editor", editor_cmd, true)

    -- Set up git credential helper based on platform
    if platform.os == "macos" then
        -- macOS: Use Keychain
        M.set_git_config("credential.helper", "osxkeychain", true)
    elseif platform.os == "windows" then
        -- Windows: Use credential manager
        M.set_git_config("credential.helper", "wincred", true)
    elseif platform.os == "wsl" then
        -- WSL: Can use Windows credential manager
        M.set_git_config("credential.helper", "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe", true)
    else
        -- Linux: Use cache with timeout
        M.set_git_config("credential.helper", "cache --timeout=3600", true)
    end

    vim.notify("Git global config configured successfully", vim.log.levels.INFO)
    return true
end

-- Clone repository with cross-platform support
M.clone_repo = function(url, path, options)
    options = options or {}

    -- Build clone command
    local cmd = "git clone"

    -- Add options
    if options.depth then
        cmd = cmd .. " --depth=" .. options.depth
    end

    if options.branch then
        cmd = cmd .. " --branch=" .. options.branch
    end

    if options.recursive then
        cmd = cmd .. " --recursive"
    end

    -- Add URL and path
    cmd = cmd .. " " .. vim.fn.shellescape(url)

    if path then
        -- Normalize path for current OS
        path = platform.normalize_path(path)
        cmd = cmd .. " " .. vim.fn.shellescape(path)
    end

    -- Execute the clone
    vim.notify("Cloning repository...", vim.log.levels.INFO)
    local output, exit_code = platform.system(cmd)

    if exit_code == 0 then
        vim.notify("Repository cloned successfully", vim.log.levels.INFO)
        return true, path
    else
        vim.notify("Failed to clone repository: " .. output, vim.log.levels.ERROR)
        return false, nil
    end
end

-- List worktrees with better cross-platform support
M.list_worktrees = function()
    local output, exit_code = platform.system("git worktree list", true)

    if exit_code ~= 0 then
        vim.notify("Failed to list worktrees", vim.log.levels.ERROR)
        return {}
    end

    local worktrees = {}

    for line in output:gmatch("[^\r\n]+") do
        local path, hash, branch = line:match("([^%s]+)%s+([^%s]+)%s+%[([^%]]+)%]")

        if path then
            -- Normalize path for the current OS
            path = platform.normalize_path(path)

            table.insert(worktrees, {
                path = path,
                hash = hash,
                branch = branch
            })
        end
    end

    return worktrees
end

-- Check if git-lfs is installed
M.has_lfs = function()
    local _, exit_code = platform.system("git lfs version", true)
    return exit_code == 0
end

-- Initialize git-lfs in repository
M.init_lfs = function()
    -- Check if git-lfs is installed
    if not M.has_lfs() then
        vim.notify("git-lfs is not installed. Please install it first.", vim.log.levels.ERROR)
        return false
    end

    -- Check if in a git repository
    if not M.get_git_root() then
        vim.notify("Not in a git repository", vim.log.levels.ERROR)
        return false
    end

    -- Initialize git-lfs
    local output, exit_code = platform.system("git lfs install")

    if exit_code ~= 0 then
        vim.notify("Failed to initialize git-lfs: " .. output, vim.log.levels.ERROR)
        return false
    end

    vim.notify("git-lfs initialized successfully", vim.log.levels.INFO)
    return true
end

-- Track files with git-lfs
M.lfs_track = function(pattern)
    if not M.has_lfs() then
        vim.notify("git-lfs is not installed. Please install it first.", vim.log.levels.ERROR)
        return false
    end

    if not pattern or pattern == "" then
        -- Show tracking patterns
        local output, exit_code = platform.system("git lfs track")

        if exit_code == 0 then
            vim.notify("Current git-lfs tracking patterns:\n" .. output, vim.log.levels.INFO)
        else
            vim.notify("Failed to get git-lfs tracking patterns", vim.log.levels.ERROR)
        end

        return exit_code == 0
    else
        -- Track new pattern
        local output, exit_code = platform.system("git lfs track " .. vim.fn.shellescape(pattern))

        if exit_code == 0 then
            vim.notify("Now tracking " .. pattern .. " with git-lfs", vim.log.levels.INFO)

            -- Add .gitattributes to git
            platform.system("git add .gitattributes", true)
        else
            vim.notify("Failed to track " .. pattern .. " with git-lfs: " .. output, vim.log.levels.ERROR)
        end

        return exit_code == 0
    end
end

return M
