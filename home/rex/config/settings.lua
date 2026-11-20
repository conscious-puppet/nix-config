-- Every Rex app setting this configuration owns.
--
-- These are app settings, not server settings: they live in the app's
-- UserDefaults and nothing in the server API reads or writes them. The app
-- exposes them as client.setting.* actions and performs them itself, so this
-- file only hands those actions over:
--
--   * apply_settings, bound to shift+cmd+, and listed in the palette, queues
--     them with rex.client.queue, which the app runs after the action returns.
--   * apply-settings.lua runs them with client.perform, and init.lua starts it
--     on every config load, so `rex config reload` pushes the settings to the
--     running app without pressing anything.
--
-- Each entry is the client.setting.* action without its prefix, and the value
-- to give it. Settings with no client.setting.* action can't be set this way:
-- window frames, sidebar width and collapse, the hidden toolbar and pane
-- buttons, the activity grouping, the last focused session, and the custom
-- theme definitions. A theme is selected by name instead: see theme.lua for
-- why a theme ID doesn't survive the move to another Mac.

local themes = require("theme")

local SETTINGS = {
  -- Interface > Appearance
  -- interface.appearance.style has no value here: the app stores "useTheme",
  -- which is not one of the action's choices (glass or classic).

  -- Interface > Toolbar and tabs
  { "interface.toolbar.layout", "above" },
  { "interface.toolbar.auto_hide_toolbar", "always_show" },
  { "interface.tab_behavior.fill", false },
  { "interface.tabs.color", "never" },

  -- Interface > Panes
  { "interface.panes.density", "compact" },
  { "interface.panes.headers", "hidden" },
  { "interface.pane_padding.horizontal", 7 },
  { "interface.pane_padding.vertical", 7 },
  { "interface.pane_padding.color", "off" },
  { "interface.pane_padding.program_background", true },
  { "interface.active_panes.active_border", true },
  { "interface.active_panes.active_border_opacity", 0.1 },
  { "interface.active_panes.fade", "off" },

  -- Interface > Window
  { "interface.window.sidebar_swipe", "off" },
  { "interface.animation.style", "natural" },

  -- Themes
  -- The dark theme is a custom one, so it is named: the app gives an imported
  -- theme an ID that is new on every Mac. The light theme is built in, so its
  -- name is also its ID.
  { "themes.dark.palette", { theme = "solarized-dark" } },
  { "themes.dark.extended_palette", true },
  { "themes.light.palette", "merino-light" },

  -- Notifications
  { "notifications.overview.position", "top_right" },

  -- Terminal > Typography
  { "terminal.typography.font", "Iosevka" },
  { "terminal.typography.size", 20 },
  { "terminal.typography.line_height", 10 },
  { "terminal.advanced_fonts.smoothing", true },

  -- Terminal > Cursor and selection
  { "terminal.cursor.style", "block" },
  { "terminal.cursor.shaders", false },
  { "terminal.cursor.shader", "frozen" },
  { "terminal.selection.background", "theme" },
  { "terminal.selection.foreground", "theme" },
  { "terminal.selection.corners", true },
  { "terminal.scrolling.smooth", true },
  { "terminal.colors.palette", false },

  -- Developer > Experiments
  { "developer.experimental.terminal_anchor", "bottom" },
  { "developer.experimental.new_quick_switcher", true },
}

local function action_name(setting)
  return "client.setting." .. setting[1]
end

-- Whether the app is on this Mac, and so shares the preferences that custom
-- theme IDs come from.
local function is_local(client)
  local transport = (client.principal or {}).transport
  return transport == "unix" or transport == "named_pipe"
end

local function client_name(client)
  return (client.info or {}).label or client.client_id
end

-- The value to send for a setting, and why it is left unsent. nil means to
-- leave the setting alone: a theme is resolved to this Mac's ID for it, and
-- when the theme isn't installed here, or the app is on another Mac, the
-- setting is skipped rather than set to an ID that means nothing there.
local function value(setting, local_app)
  local wanted = setting[2]
  if type(wanted) ~= "table" or wanted.theme == nil then
    return wanted
  end
  if not local_app then
    return nil
  end

  local id, err = themes.id(wanted.theme)
  return id, id == nil and ("theme: " .. tostring(err)) or nil
end

local M = { settings = SETTINGS }

-- Ask the client that ran the action to perform every setting, in order.
function M.queue()
  for _, setting in ipairs(SETTINGS) do
    local chosen, problem = value(setting, true)
    if problem ~= nil then
      rex.log("warn", "settings: " .. problem)
    end
    if chosen ~= nil then
      rex.client.queue(action_name(setting), { value = chosen })
    end
  end
end

-- Ask every connected app to perform every setting and return what went
-- wrong, one entry per app or setting it couldn't send. apply-settings.lua
-- calls this from rex do, where the caller is the CLI rather than the app, and
-- the app has to accept actions: Remote Control on in its Settings under
-- Server.
function M.push()
  local clients, err = rex.call("client.list", {})
  if clients == nil then
    error(err, 0)
  end

  local problems = {}
  for _, client in ipairs(clients.clients or {}) do
    if (client.info or {}).kind == "app" then
      local local_app = is_local(client)

      for _, setting in ipairs(SETTINGS) do
        local chosen, problem = value(setting, local_app)
        if problem ~= nil then
          problems[#problems + 1] = problem
        end

        if chosen ~= nil then
          local res, why = rex.call("client.perform", {
            client_id = client.client_id,
            action = action_name(setting),
            args = { value = chosen },
          })
          -- The app refused, or left while this ran: stop sending to it rather
          -- than repeat the same refusal for every remaining setting.
          if res == nil then
            problems[#problems + 1] = ("%s: %s"):format(client_name(client), why)
            break
          end
        end
      end
    end
  end
  return problems
end

rex.action({
  name = "apply_settings",
  title = "Apply Settings from Config",
  description = "Send every setting in the configuration file to this app.",
  category = "Settings",
  keywords = "settings preferences apply push sync reload",
  run = function()
    M.queue()
  end,
})

rex.bind("shift+cmd+,", "apply_settings")

return M
