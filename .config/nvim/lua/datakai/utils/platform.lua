-- Cross-platform utilities for Neovim
-- This file provides helper functions to ensure compatibility across
-- macOS, Linux, WSL, and Windows

local M = {}

-- Detect operating system
M.os = (function()
    local os_name = vim.loop.os_uname().sysname
    local is_wsl = vim.fn.has('wsl') == 1 or (function()
        local output = vim.fn.system('uname -r')
        return output:lower():match('wsl') ~= nil or output:lower():match('microsoft') ~= nil
    end)()

    if os_name == "Darwin" then
        return "macos"
    elseif os_name == "Linux" and is_wsl then
        return "wsl"
    elseif os_name == "Linux" then
        return "linux"
    elseif os_name:match('Windows') or os_name:match('MINGW') or os_name:match('MSYS') then
        return "windows"
    else
        return "unknown"
    end
end)()

-- Normalize path for current OS
-- Converts between Unix and Windows paths as needed
M.normalize_path = function(path)
    -- Expand ~ to full home directory
    path = vim.fn.expand(path)

    if M.os == "windows" then
        -- Convert Unix paths to Windows
        path = path:gsub("/", "\\")

        -- Make sure drive letter is uppercase
        local drive = path:match("^(%a):")
        if drive then
            path = drive:upper() .. path:sub(2)
        end
    elseif M.os == "wsl" and path:match("^/mnt/%a/") then
        -- Special case for WSL Windows paths
        -- Can either keep as /mnt/c/... or convert to Windows format
        -- Depending on the context needed
    else
        -- Convert Windows paths to Unix
        path = path:gsub("\\", "/")
    end

    return path
end

-- Get proper home directory
M.get_home = function()
    if M.os == "windows" then
        return os.getenv("USERPROFILE") or vim.fn.expand("$HOME")
    else
        return os.getenv("HOME") or vim.fn.expand("$HOME")
    end
end

-- Get Windows home from WSL
M.get_win_home = function()
    if M.os == "wsl" then
        -- Try to get the Windows username from the environment
        local win_username = vim.fn.trim(vim.fn.system("cmd.exe /c 'echo %USERNAME%'"))
        return "/mnt/c/Users/" .. win_username
    elseif M.os == "windows" then
        return M.get_home()
    else
        return nil -- Not applicable
    end
end

-- Cross-platform clipboard support
M.setup_clipboard = function()
    if M.os == "wsl" then
        vim.g.clipboard = {
            name = "win32yank-wsl",
            copy = {
                ["+"] = "clip.exe",
                ["*"] = "clip.exe",
            },
            paste = {
                ["+"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
                ["*"] = "powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace(\"`r\", \"\"))",
            },
            cache_enabled = 0,
        }
    elseif M.os == "macos" then
        -- macOS uses pbcopy and pbpaste by default, handled by unnamedplus
        -- No additional configuration needed
    elseif M.os == "linux" then
        -- For Linux, ensure xclip or xsel is installed
        if vim.fn.executable("xclip") == 1 then
            -- Configuration is handled by unnamedplus
        elseif vim.fn.executable("xsel") == 1 then
            -- Configuration is handled by unnamedplus
        else
            vim.notify("Please install xclip or xsel for clipboard support", vim.log.levels.WARN)
        end
    end
end

-- Get proper path separator
M.get_separator = function()
    if M.os == "windows" then
        return "\\"
    else
        return "/"
    end
end

-- Execute a system command with better cross-platform support
M.system = function(cmd, silent)
    local output

    -- Adjust command for the OS
    if M.os == "windows" and not cmd:match("^cmd.exe") and not cmd:match("^powershell") then
        -- Wrap in cmd.exe for Windows
        cmd = "cmd.exe /c " .. cmd
    end

    -- Execute the command
    if not silent then
        vim.cmd("echo 'Running: " .. cmd:gsub("'", "''") .. "'")
    end

    output = vim.fn.system(cmd)

    if not silent and vim.v.shell_error ~= 0 then
        vim.cmd("echo 'Error: " .. output:gsub("'", "''") .. "'")
    end

    return output, vim.v.shell_error
end

-- Open a URL in the default browser
M.open_url = function(url)
    local cmd

    if M.os == "macos" then
        cmd = "open " .. vim.fn.shellescape(url)
    elseif M.os == "wsl" then
        cmd = "wslview " .. vim.fn.shellescape(url)
    elseif M.os == "linux" then
        cmd = "xdg-open " .. vim.fn.shellescape(url)
    elseif M.os == "windows" then
        cmd = "start " .. vim.fn.shellescape(url)
    else
        vim.notify("Unsupported OS for opening URLs", vim.log.levels.ERROR)
        return
    end

    vim.fn.system(cmd)
end

-- Create a directory if it doesn't exist
M.ensure_directory = function(dir)
    dir = M.normalize_path(dir)

    if vim.fn.isdirectory(dir) == 0 then
        if M.os == "windows" then
            vim.fn.system('mkdir "' .. dir .. '"')
        else
            vim.fn.system('mkdir -p "' .. dir .. '"')
        end

        return vim.fn.isdirectory(dir) == 1
    end

    return true
end

-- Get valid path for data directories
M.get_data_dir = function(name)
    local data_dir = vim.fn.stdpath('data')
    local path = data_dir .. M.get_separator() .. name

    M.ensure_directory(path)
    return path
end

-- Detect second-brain location across platforms
M.get_brain_dir = function()
    local home = M.get_home()
    local candidates = {
        home .. "/second-brain",
        home .. "/Documents/second-brain",
    }

    -- WSL might have second-brain in Windows home
    if M.os == "wsl" then
        local win_home = M.get_win_home()
        if win_home then
            table.insert(candidates, win_home .. "/second-brain")
            table.insert(candidates, win_home .. "/Documents/second-brain")

            -- Also check OneDrive
            table.insert(candidates, win_home .. "/OneDrive/second-brain")
            table.insert(candidates, win_home .. "/OneDrive - West Monroe/second-brain")
        end
    end

    -- Check all candidates
    for _, path in ipairs(candidates) do
        if vim.fn.isdirectory(path) == 1 then
            return path
        end
    end

    -- Default to home dir if not found
    return home .. "/second-brain"
end

-- Get os independent command for opening terminal
M.get_terminal_cmd = function()
    if M.os == "macos" then
        return "open -a Terminal"
    elseif M.os == "wsl" or M.os == "windows" then
        return "wt.exe"
    elseif M.os == "linux" then
        -- Try several terminal emulators
        for _, term in ipairs({ "gnome-terminal", "konsole", "xterm" }) do
            if vim.fn.executable(term) == 1 then
                return term
            end
        end
        return "x-terminal-emulator" -- Debian/Ubuntu alternative
    end

    return nil -- No supported terminal found
end

-- Setup shell detection
M.get_shell = function()
    local shell = os.getenv("SHELL")

    if not shell or shell == "" then
        if M.os == "windows" then
            -- Check for common Windows shells
            if vim.fn.executable("pwsh") == 1 then
                return "pwsh"
            elseif vim.fn.executable("powershell") == 1 then
                return "powershell"
            else
                return "cmd.exe"
            end
        else
            -- Default to bash on Unix-like systems
            return "/bin/bash"
        end
    end

    return shell
end

-- Function to check if a command is available
M.command_exists = function(cmd)
    if M.os == "windows" then
        -- Windows requires different command to check if executable exists
        local _, code = M.system("where " .. cmd .. " >nul 2>nul", true)
        return code == 0
    else
        -- Unix-like systems can use which
        local _, code = M.system("which " .. cmd .. " >/dev/null 2>&1", true)
        return code == 0
    end
end

return M
