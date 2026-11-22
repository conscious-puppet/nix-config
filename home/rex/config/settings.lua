-- Settings the app keeps in its own preferences. Run once per machine from
-- the command palette ("Import Theme", then "Apply Settings"); both are
-- safe to run again. Works with Remote Control off: the queued client
-- actions come from this config, not from an outside caller.
--
-- Not everything the app remembers can be set from here. The floating
-- taskbar corner moves by dragging it (its own setting says so), and the
-- tab icon tint, hidden chrome buttons, activity grouping, and the sidebar
-- state have no setting actions at all. Position those once per Mac by hand.
local util = require("util")

local module = {}

local THEMES = util.HOME .. "/.cache/rex/themes"
local THEME_FILE = util.HOME .. "/.config/rex/solarized-dark.toml"

-- Values as they were in the app's preferences when this file was written.
-- Choice settings need the app's raw values, which can differ from what
-- the plist holds (e.g. headers is "hidden", not the legacy "never"); a
-- wrong one fails the run and names the valid choices.
local SETTINGS = {
  -- Themes
  { "client.setting.themes.dark.palette", { value = "solarized-dark" } },
  { "client.setting.themes.dark.extended_palette", { value = true } },
  { "client.setting.themes.light.palette", { value = "merino-light" } },

  -- Terminal: typography, cursor, colors, scrolling, selection
  { "client.setting.terminal.typography.font", { value = "Iosevka" } },
  { "client.setting.terminal.typography.size", { value = 20 } },
  { "client.setting.terminal.typography.line_height", { value = 15 } },
  { "client.setting.terminal.advanced_fonts.smoothing", { value = true } },
  { "client.setting.terminal.cursor.style", { value = "block" } },
  { "client.setting.terminal.cursor.shaders", { value = false } },
  { "client.setting.terminal.cursor.shader", { value = "frozen" } },
  { "client.setting.terminal.colors.palette", { value = false } },
  { "client.setting.terminal.scrolling.smooth", { value = true } },
  { "client.setting.terminal.selection.background", { value = "theme" } },
  { "client.setting.terminal.selection.foreground", { value = "theme" } },
  { "client.setting.terminal.selection.corners", { value = true } },

  -- Interface: panes, padding, tabs and toolbar, window
  { "client.setting.interface.panes.density", { value = "comfortable" } },
  { "client.setting.interface.panes.headers", { value = "hidden" } },
  { "client.setting.interface.active_panes.active_border", { value = true } },
  { "client.setting.interface.active_panes.active_border_opacity", { value = 0.1 } },
  { "client.setting.interface.active_panes.fade", { value = "both" } },
  { "client.setting.interface.animation.style", { value = "natural" } },
  { "client.setting.interface.pane_padding.horizontal", { value = 7 } },
  { "client.setting.interface.pane_padding.vertical", { value = 7 } },
  { "client.setting.interface.pane_padding.color", { value = "automatic" } },
  { "client.setting.interface.toolbar.layout", { value = "above" } },
  { "client.setting.interface.toolbar.auto_hide_toolbar", { value = "always_show" } },
  { "client.setting.interface.tab_behavior.fill", { value = false } },
  { "client.setting.interface.tabs.color", { value = "always" } },
  { "client.setting.interface.window.sidebar_swipe", { value = "off" } },

  -- Notifications
  { "client.setting.notifications.overview.position", { value = "top_right" } },

  -- Experiments kept on
  { "client.setting.developer.experimental.new_quick_switcher", { value = true } },
  { "client.setting.developer.experimental.terminal_anchor", { value = "top" } },
}

rex.action({
  name = "import_theme",
  title = "Import Theme: Solarized Dark",
  description = "Copy solarized-dark.toml into the app's themes (named solarized-dark) and import it. Safe to run again after the file changes.",
  category = "Settings",
  keywords = "theme solarized dark import colors palette",
  run = function(ctx, args)
    local src = assert(io.open(THEME_FILE, "r"))
    local text = src:read("*a")
    src:close()

    util.run({ "mkdir", "-p", THEMES })
    -- Rex names an imported theme after its file, so the copy is written
    -- without an extension. It is a snapshot: run this again after editing
    -- solarized-dark.toml.
    local dst = assert(io.open(THEMES .. "/solarized-dark", "w"))
    dst:write(text)
    dst:close()

    rex.client.queue("client.theme.import", { path = THEMES .. "/solarized-dark" })
  end,
})

rex.action({
  name = "apply_settings",
  title = "Apply Settings",
  description = "Set the app settings kept in nix-config's home/rex/config/settings.lua. Safe to run again.",
  category = "Settings",
  keywords = "settings preferences font theme palette apply",
  run = function(ctx, args)
    for _, setting in ipairs(SETTINGS) do
      rex.client.queue(setting[1], setting[2])
    end
  end,
})

return module

