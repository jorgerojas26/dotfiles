local config = {}
local wezterm = require("wezterm")

config.font = wezterm.font("Fira Code")
config.font_size = 16
config.default_cursor_style = "BlinkingBar"
config.animation_fps = 60
config.cursor_blink_rate = 500
config.max_fps = 120

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.enable_tab_bar = false
config.scrollback_lines = 5000
config.window_background_opacity = 0.95

-- config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- config.keys = {
-- 	{
-- 		mods = "LEADER",
-- 		key = "-",
-- 		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
-- 	},
-- 	{
-- 		mods = "LEADER",
-- 		key = "\\",
-- 		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
-- 	},
-- 	{ key = "s", mods = "LEADER", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
-- 	{ key = "w", mods = "LEADER", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
-- 	{ mods = "LEADER", key = "z", action = wezterm.action.TogglePaneZoomState },
-- 	{
-- 		key = ",",
-- 		mods = "LEADER",
-- 		action = wezterm.action.PromptInputLine({
-- 			description = "Enter new name for tab",
-- 			action = wezterm.action_callback(function(window, pane, line)
-- 				-- line will be `nil` if they hit escape without entering anything
-- 				-- An empty string if they just hit enter
-- 				-- Or the actual line of text they wrote
-- 				if line then
-- 					window:active_tab():set_title(line)
-- 				end
-- 			end),
-- 		}),
-- 	},
-- 	{
-- 		key = "h",
-- 		mods = "CTRL",
-- 		action = wezterm.action.ActivatePaneDirection("Left"),
-- 	},
-- 	{
-- 		key = "l",
-- 		mods = "CTRL",
-- 		action = wezterm.action.ActivatePaneDirection("Right"),
-- 	},
-- 	{
-- 		key = "k",
-- 		mods = "CTRL",
-- 		action = wezterm.action.ActivatePaneDirection("Up"),
-- 	},
-- 	{
-- 		key = "j",
-- 		mods = "CTRL",
-- 		action = wezterm.action.ActivatePaneDirection("Down"),
-- 	},
-- 	{
-- 		key = "c",
-- 		mods = "LEADER",
-- 		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
-- 	},
-- 	-- split_nav("move", "h"),
-- 	-- split_nav("move", "j"),
-- 	-- split_nav("move", "k"),
-- 	-- split_nav("move", "l"),
-- 	-- resize panes
-- 	-- split_nav("resize", "h"),
-- 	-- split_nav("resize", "j"),
-- 	-- split_nav("resize", "k"),
-- 	-- split_nav("resize", "l"),
-- }

config.window_decorations = "RESIZE"
config.native_macos_fullscreen_mode = false

wezterm.on("window-config-reloaded", function(window)
	local appearance = window:get_appearance()
	local color_scheme = appearance == "Light" and "catppuccin-latte" or "Catppuccin Mocha"

	window:set_config_overrides({ color_scheme = color_scheme })
end)

wezterm.on("gui-startup", function()
	local tab, pane, window = wezterm.mux.spawn_window({})
	window:gui_window():maximize()
end)

return config
