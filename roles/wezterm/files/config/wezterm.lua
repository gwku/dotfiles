local wezterm = require("wezterm")
local config = wezterm.config_builder()

local neofusion_theme = {
	foreground = "#e0d9c7",
	background = "#070f1c",
	cursor_bg = "#e0d9c7",
	cursor_border = "#e0d9c7",
	cursor_fg = "#070f1c",
	selection_bg = "#ea6847",
	selection_fg = "#e0d9c7",
	ansi = {
		"#070f1c", -- Black (Host)
		"#ea6847", -- Red (Syntax string)
		"#ea6847", -- Green (Command)
		"#5db2f8", -- Yellow (Command second)
		"#2f516c", -- Blue (Path)
		"#d943a8", -- Magenta (Syntax var)
		"#86dbf5", -- Cyan (Prompt)
		"#e0d9c7", -- White
	},
	brights = {
		"#2f516c", -- Bright Black
		"#d943a8", -- Bright Red (Command error)
		"#ea6847", -- Bright Green (Exec)
		"#86dbf5", -- Bright Yellow
		"#5db2f8", -- Bright Blue (Folder)
		"#d943a8", -- Bright Magenta
		"#ea6847", -- Bright Cyan
		"#e0d9c7", -- Bright White
	},
}

config = {
	colors = neofusion_theme,
	default_prog = { "/usr/bin/fish", "-l" },
  window_decorations = "RESIZE"
}

return config
