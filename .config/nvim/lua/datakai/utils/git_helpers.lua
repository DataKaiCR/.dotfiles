-- Contains utility functions shared between git modules

local M = {}

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
    local cmd = "git ls-files --error-unmatch " .. vim.fn.shellescape(file_path) .. " > /dev/null 2>&1"
    local exit_code = os.execute(cmd)
    return exit_code == 0
end

-- Get file git status
M.get_file_status = function(file_path)
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

    return result ~= "" and result or nil
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
        gitignore_path = root .. "/.gitignore"
    else
        -- Add to nearest .gitignore (or create one)
        gitignore_path = vim.fn.getcwd() .. "/.gitignore"
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

    local hook_path = root .. "/.git/hooks/" .. hook_name

    -- Create hooks directory if needed
    vim.fn.mkdir(root .. "/.git/hooks/", "p")

    -- Write hook file
    local file = io.open(hook_path, "w")
    if file then
        file:write("#!/bin/sh\n\n")
        file:write(content)
        file:close()

        -- Make executable
        vim.fn.system("chmod +x " .. vim.fn.shellescape(hook_path))

        vim.notify("Created git hook: " .. hook_name, vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to create git hook: " .. hook_name, vim.log.levels.ERROR)
        return false
    end
end

return M
