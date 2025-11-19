-- Enhanced Wezterm Configuration with Project Awareness
-- Compatible with: macOS, Windows, WSL, Linux
-- Optimized: 2025-11-18 with smart features
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- Define configuration
local config = {}

-- Configuration builder (newer Wezterm versions)
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- ============================================================================
-- PLATFORM DETECTION
-- ============================================================================

local os_name = wezterm.target_triple
local is_windows = os_name:find('windows') ~= nil
local is_mac = os_name:find('darwin') ~= nil
local is_linux = os_name:find('linux') ~= nil
local is_wsl = false

-- Check for WSL
if is_linux then
    local success, stdout, stderr = wezterm.run_child_process({ "uname", "-r" })
    is_wsl = success and stdout:find("WSL") ~= nil
end

-- Home directory (cross-platform)
local home_dir = os.getenv('HOME') or os.getenv('USERPROFILE')

-- ============================================================================
-- PROJECT DETECTION & METADATA
-- ============================================================================

-- Parse .project.toml file
local function parse_project_toml(cwd)
    if not cwd then return nil end

    local project_file = cwd .. "/.project.toml"
    local f = io.open(project_file, "r")
    if not f then return nil end

    local content = f:read("*all")
    f:close()

    local project = {
        name = content:match('name%s*=%s*"([^"]+)"'),
        owner = content:match('primary%s*=%s*"([^"]+)"'),
        status = content:match('status%s*=%s*"([^"]+)"'),
    }

    return project.name and project or nil
end

-- Detect git branch in directory
local function get_git_branch(cwd)
    if not cwd then return nil end

    local success, stdout = wezterm.run_child_process({ "git", "-C", cwd, "branch", "--show-current" })
    if success and stdout then
        return stdout:gsub("%s+", "")
    end
    return nil
end

-- Get project context from cwd
local function get_project_context(cwd)
    if not cwd then return nil end

    -- Remove file:// prefix if present
    local path = cwd
    if path:match("^file://") then
        path = path:gsub("^file://", "")
        -- Remove hostname on Unix systems
        path = path:gsub("^/[^/]+/", "/")
    end

    local context = {
        cwd = path,
        name = path:match("([^/]+)$"),  -- Last directory
        git_branch = get_git_branch(path),
    }

    -- Try to get project metadata
    local project = parse_project_toml(path)
    if project then
        context.project_name = project.name
        context.owner = project.owner
        context.status = project.status
    end

    return context
end

-- ============================================================================
-- COLOR SCHEMES PER PROJECT
-- ============================================================================

local project_color_schemes = {
    datakai = "Tokyo Night Storm",
    westmonroe = "Gruvbox Dark",
    default = "Tokyo Night Storm",
}

-- ============================================================================
-- STARTUP: Maximize window and auto-attach to tmux
-- ============================================================================

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {
        args = { '/bin/zsh', '-l', '-c', 'tmux attach || tmux' }
    })
    window:gui_window():maximize()
end)

-- ============================================================================
-- TAB BAR: Enhanced with project context
-- ============================================================================

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    local context = get_project_context(pane.current_working_dir)

    if not context then
        return tab.active_pane.title
    end

    local title = ""

    -- Add owner icon if available
    if context.owner then
        if context.owner == "datakai" then
            title = " "  -- Personal icon
        elseif context.owner == "westmonroe" then
            title = " "  -- Work icon
        end
    end

    -- Add project name
    if context.project_name then
        title = title .. context.project_name
    else
        title = title .. context.name
    end

    -- Add git branch if available
    if context.git_branch and context.git_branch ~= "" then
        title = title .. " (" .. context.git_branch .. ")"
    end

    -- Ensure we don't exceed max_width
    if #title > max_width then
        title = title:sub(1, max_width - 1) .. "…"
    end

    return title
end)

-- ============================================================================
-- STATUS BAR: Show context info
-- ============================================================================

wezterm.on('update-right-status', function(window, pane)
    local context = get_project_context(pane:get_current_working_dir())

    if not context then
        window:set_right_status('')
        return
    end

    local status = {}

    -- Git identity
    if context.owner then
        table.insert(status, " " .. context.owner)
    end

    -- Git branch
    if context.git_branch and context.git_branch ~= "" then
        table.insert(status, " " .. context.git_branch)
    end

    -- Project status
    if context.status then
        local status_icon = context.status == "active" and "●" or "○"
        table.insert(status, status_icon .. " " .. context.status)
    end

    window:set_right_status(table.concat(status, " | "))
end)

-- ============================================================================
-- DYNAMIC COLOR SCHEME: Change based on project owner
-- ============================================================================

wezterm.on('window-focus-changed', function(window, pane)
    local context = get_project_context(pane:get_current_working_dir())

    if context and context.owner and project_color_schemes[context.owner] then
        window:set_config_overrides({
            color_scheme = project_color_schemes[context.owner]
        })
    else
        window:set_config_overrides({
            color_scheme = project_color_schemes.default
        })
    end
end)

-- ============================================================================
-- BASIC CONFIGURATION
-- ============================================================================

config.color_scheme = 'Tokyo Night Storm'
config.font = wezterm.font('Hack Nerd Font')
config.font_size = 13  -- Increased from 11 for better readability

-- Cursor configuration
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Tab bar styling
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false  -- Always show for context

-- Window decorations
if is_mac then
    config.window_decorations = 'RESIZE'
elseif is_windows or is_wsl then
    config.window_decorations = 'RESIZE'
else
    config.window_decorations = 'RESIZE'
end

-- Background configuration
config.window_background_opacity = 0.90  -- Slightly more transparent
config.macos_window_background_blur = 20

-- Text rendering
config.foreground_text_hsb = {
    hue = 1.0,
    saturation = 1.2,
    brightness = 1.5,
}

-- Performance settings
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.animation_fps = 60

-- ============================================================================
-- KEYBINDINGS
-- ============================================================================

config.disable_default_key_bindings = true
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }
config.use_dead_keys = false

config.keys = {
    -- Terminal copy mode
    { key = 'ñ', mods = 'LEADER', action = act.ActivateCopyMode },

    -- Pane and window management
    { key = 'f', mods = 'ALT',    action = act.TogglePaneZoomState },
    { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'LEADER', action = act.ShowTabNavigator },
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentTab { confirm = false } },

    -- Domain management
    { key = 'a', mods = 'LEADER', action = act.AttachDomain 'unix' },
    { key = 'd', mods = 'LEADER', action = act.DetachDomain { DomainName = 'unix' } },

    -- Session management
    {
        key = '$',
        mods = 'LEADER|SHIFT',
        action = act.PromptInputLine {
            description = 'Enter new name for session',
            action = wezterm.action_callback(
                function(window, pane, line)
                    if line then
                        mux.rename_workspace(
                            window:mux_window():get_workspace(),
                            line
                        )
                    end
                end
            ),
        },
    },

    -- Workspace selection
    {
        key = 's',
        mods = 'LEADER',
        action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
    },

    -- Launcher and clipboard
    { key = 'l', mods = 'ALT',    action = act.ShowLauncher },
    { key = 'C', mods = 'CTRL',   action = act.CopyTo 'Clipboard' },
    { key = 'V', mods = 'CTRL',   action = act.PasteFrom 'Clipboard' },

    -- Pane navigation (seamless with tmux via vim-tmux-navigator)
    { key = 'k', mods = 'CTRL',   action = act.ActivatePaneDirection 'Up' },
    { key = 'j', mods = 'CTRL',   action = act.ActivatePaneDirection 'Down' },
    { key = 'h', mods = 'CTRL',   action = act.ActivatePaneDirection 'Left' },
    { key = 'l', mods = 'CTRL',   action = act.ActivatePaneDirection 'Right' },

    -- Tab and window management
    { key = 't', mods = 'CTRL',   action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'N', mods = 'CTRL',   action = act.SpawnWindow },
    { key = 'x', mods = 'CTRL',   action = act.CloseCurrentPane { confirm = false } },
    { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
    { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },

    -- Split panes
    { key = ',', mods = 'CTRL',   action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
    { key = '.', mods = 'CTRL',   action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },

    -- Edit this config file (using HOME variable)
    {
        key = '.',
        mods = 'LEADER',
        action = act.SpawnCommandInNewTab {
            cwd = home_dir .. '/.config/wezterm',
            args = {
                '/usr/bin/env',
                'nvim',
                home_dir .. '/.config/wezterm/wezterm.lua',
            },
        },
    },

    -- Rename tab
    {
        key = ',',
        mods = 'LEADER',
        action = act.PromptInputLine {
            description = 'Name your tab',
            action = wezterm.action_callback(function(window, pane, line)
                if line then
                    window:active_tab():set_title(line)
                end
            end),
        },
    },

    -- Tmux sessionizer integration (using HOME variable)
    {
        key = 'f',
        mods = 'LEADER',
        action = act.SpawnCommandInNewWindow {
            args = { home_dir .. '/.local/bin/tmux-sessionizer' },
        },
    },
}

-- ============================================================================
-- MOUSE CONFIGURATION
-- ============================================================================

config.mouse_bindings = {
    -- Right click paste
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom 'Clipboard',
    },
}

-- ============================================================================
-- DOMAINS
-- ============================================================================

config.unix_domains = {
    {
        name = 'unix',
    },
}

-- Setup OS-specific domains and configurations
if is_windows then
    config.default_domain = 'local'
    table.insert(config.keys, { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnWindow })
elseif is_wsl then
    config.default_domain = 'WSL:Ubuntu'
elseif is_mac then
    config.default_domain = 'local'
    config.native_macos_fullscreen_mode = true
    config.enable_kitty_keyboard = true
else
    config.default_domain = 'local'
end

-- ============================================================================
-- LAUNCH MENU
-- ============================================================================

config.launch_menu = {}

if is_mac then
    table.insert(config.launch_menu, {
        label = "macOS Terminal",
        args = { "/usr/bin/env", "zsh", "-l" },
    })
    table.insert(config.launch_menu, {
        label = "Fish Shell",
        args = { "/usr/bin/env", "fish", "-l" },
    })
elseif is_windows then
    table.insert(config.launch_menu, {
        label = "PowerShell",
        args = { "powershell.exe", "-NoLogo" },
    })
    table.insert(config.launch_menu, {
        label = "Command Prompt",
        args = { "cmd.exe" },
    })
else
    table.insert(config.launch_menu, {
        label = "Bash",
        args = { "/usr/bin/env", "bash", "-l" },
    })
    table.insert(config.launch_menu, {
        label = "Zsh",
        args = { "/usr/bin/env", "zsh", "-l" },
    })
end

-- Common launch options
table.insert(config.launch_menu, {
    label = "Neovim",
    args = { "/usr/bin/env", "nvim" },
})

return config
