-- Enhanced Wezterm Configuration with Cross-Platform Support
-- Compatible with: macOS, Windows, WSL, Linux
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- Define configuration
local config = {}

-- Configuration builder (newer Wezterm versions)
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Detect OS
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

-- Maximize window on startup and auto-attach to tmux
wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {
        args = { '/bin/zsh', '-l', '-c', 'tmux attach || tmux' }
    })
    window:gui_window():maximize()
end)

-- Basic configuration
config.color_scheme = 'Tokyo Night Storm'
config.font = wezterm.font('Hack Nerd Font')
config.font_size = 11

-- Cursor configuration
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Tab bar styling
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

-- Window decorations - custom for each OS
if is_mac then
    config.window_decorations = 'RESIZE'
elseif is_windows or is_wsl then
    config.window_decorations = 'RESIZE'
else
    config.window_decorations = 'RESIZE'
end

-- Background configuration
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20

-- Text rendering
config.foreground_text_hsb = {
    hue = 1.0,
    saturation = 1.2,
    brightness = 1.5,
}

-- Performance settings
config.front_end = "WebGpu" -- Try WebGpu for better performance
config.webgpu_power_preference = "HighPerformance"
config.animation_fps = 60

-- Keybindings
config.disable_default_key_bindings = true
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }
config.use_dead_keys = false

-- Define key bindings
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

    -- Pane navigation
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

    -- Edit this config file
    {
        key = '.',
        mods = 'LEADER',
        action = act.SpawnCommandInNewTab {
            cwd = os.getenv('WEZTERM_CONFIG_DIR'),
            set_environment_variables = {
                TERM = 'screen-256color',
            },
            args = {
                '/usr/bin/env',
                'nvim',
                os.getenv('WEZTERM_CONFIG_FILE'),
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

    -- Tmux sessionizer integration
    {
        key = 'f',
        mods = 'LEADER',
        action = act.SpawnCommandInNewWindow {
            args = { '/Users/hstecher/.local/bin/tmux-sessionizer' },
        },
    },
}

-- Mouse config
config.mouse_bindings = {
    -- Right click paste
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom 'Clipboard',
    },
}

-- Define domains for different platforms
config.unix_domains = {
    {
        name = 'unix',
    },
}

-- Setup OS-specific domains and configurations
if is_windows then
    -- Windows-specific settings
    config.default_domain = 'local'
    table.insert(config.keys, { key = 'n', mods = 'CTRL|SHIFT', action = act.SpawnWindow })
elseif is_wsl then
    -- WSL-specific settings
    config.default_domain = 'WSL:Ubuntu'
elseif is_mac then
    -- macOS-specific settings
    config.default_domain = 'local'
    config.native_macos_fullscreen_mode = true
    -- Add macOS terminal notification support
    config.enable_kitty_keyboard = true
else
    -- Linux-specific settings
    config.default_domain = 'local'
end

-- Define launch menu items based on OS
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
    -- Linux/WSL options
    table.insert(config.launch_menu, {
        label = "Bash",
        args = { "/usr/bin/env", "bash", "-l" },
    })
    table.insert(config.launch_menu, {
        label = "Zsh",
        args = { "/usr/bin/env", "zsh", "-l" },
    })
end

-- Common launch options across all platforms
table.insert(config.launch_menu, {
    label = "Neovim",
    args = { "/usr/bin/env", "nvim" },
})

return config
