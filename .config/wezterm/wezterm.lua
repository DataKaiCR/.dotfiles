-- Wezterm Basics
-- Mux is multiplexes for windows etc inside of the terminal
-- Action is to perform actions on the terminal
local wezterm = require 'wezterm'
local mux = wezterm.mux
local act = wezterm.action

-- These are vars to put things in later
local config = {}
local keys = {}
local mouse_bindings = {}
local launch_menu = {}

-- wezterm start --nvim $XPG_CONFIG_HOME/wezterm/wezterm.lua

if wezterm.config_builder() then
	config = wezterm.config_builder()
end

-- Some tweaks for starting up Wezterm
-- Maximized window
wezterm.on('gui-startup', function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)
-- Status bar on top right that shows current workspace and date


-- Color schemes may be found in https://wezfurlong.org/wezterm/colorschemes/index.html
config.color_scheme = 'Batman'
config.font = wezterm.font('Hack Nerd Font')
config_font_size = 11
config.launch_menu = launch_menu

--blinking cursor
config.default_cursor_style = 'BlinkingBar'
config.disable_default_key_bindings = true 

-- tab
config.use_fancy_tab_bar = false
config.window_decorations = 'RESIZE'
config.tab_bar_at_bottom = true

-- adds ability to use ctrl+v to paste from clipboard
config.mouse_bindings = mouse_bindings

-- foreground tweaks
config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.2,
	brightness = 1.5,
}

-- unix domain config
config.unix_domains = {
	{
		name = 'unix',
	},
}

config.window_background_opacity = 0.9
config.switch_to_last_active_tab_when_closing_tab = true
config.disable_default_key_bindings = true
config.use_dead_keys = false
-- key bindings
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }
config.keys = {
	{ key = 'ñ', mods = 'LEADER', action = act.ActivateCopyMode },
	{ key = 'f', mods = 'ALT', action = act.TogglePaneZoomState },
	{ key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
	{ key = 'w', mods = 'LEADER', action = act.ShowTabNavigator },
	{ key = 'x', mods = 'LEADER', action = act.CloseCurrentTab { confirm = false } },
	{ key = 'a', mods = 'LEADER', action = act.AttachDomain 'unix'  },
	{ key = 'd', mods = 'LEADER', action = act.DetachDomain { DomainName = 'unix' } },

	-- Rename current session; analagous to command in tmux
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
	{
		key = 's',
		mods = 'LEADER',
		action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
	},

	{ key = 'l', mods = 'ALT', action = act.ShowLauncher },
	{ key = 'C', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
	{ key = 'V', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
	{ key = 'k', mods = 'CTRL', action = act.ActivatePaneDirection 'Up' },
	{ key = 'j', mods = 'CTRL', action = act.ActivatePaneDirection 'Down' },
	{ key = 'h', mods = 'CTRL', action = act.ActivatePaneDirection 'Left' },
	{ key = 'l', mods = 'CTRL', action = act.ActivatePaneDirection 'Right' },
	{ key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
	{ key = 'N', mods = 'CTRL', action = act.SpawnWindow },
	-- { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab { confirm = false } },
	{ key = 'x', mods = 'CTRL', action = act.CloseCurrentPane { confirm = false } },
	{ key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
	{ key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
	{ key = ',', mods = 'CTRL', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
	{ key = '.', mods = 'CTRL', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
	{ 
		key = '.', mods = 'LEADER', action = act.SpawnCommandInNewTab { 
			cwd = os.getenv('WEZTERM_CONFIG_DIR'),
			set_environment_variables = {
				TERM = 'screen-256color',
			},
			args = {
				'/usr/local/bin/nvim',
				os.getenv('WEZTERM_CONFIG_FILE'),
			},
		},
	},
	{
		key = ',', mods = 'LEADER', action = act.PromptInputLine {
			description = 'Name your tab',
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window.active_tab():set_title(line)
				end
			end),
		},
	},
}


config.default_domain = 'WSL:Ubuntu'

return config
