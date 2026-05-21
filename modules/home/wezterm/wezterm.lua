local wezterm = require("wezterm")
local config  = wezterm.config_builder()

-- Appearance
config.color_scheme = "neofusion"
config.font         = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
  "Apple Color Emoji",
})
config.font_size = 14.0
config.line_height = 1.1

config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_background_opacity = 0.98
config.macos_window_background_blur = 20

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false

-- Behavior
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false

-- Shell — managed by Nix at the system level; Wezterm picks up the
-- user's login shell automatically. No need to set default_prog.

-- Keybindings
local act = wezterm.action
config.keys = {
  { key = "t", mods = "CMD",       action = act.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CMD",       action = act.CloseCurrentTab { confirm = true } },
  { key = "d", mods = "CMD",       action = act.SplitHorizontal { domain = "CurrentPaneDomain" } },
  { key = "d", mods = "CMD|SHIFT", action = act.SplitVertical   { domain = "CurrentPaneDomain" } },
  { key = "LeftArrow",  mods = "CMD|ALT", action = act.ActivatePaneDirection("Left")  },
  { key = "RightArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow",    mods = "CMD|ALT", action = act.ActivatePaneDirection("Up")    },
  { key = "DownArrow",  mods = "CMD|ALT", action = act.ActivatePaneDirection("Down")  },
  { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },
}

return config
