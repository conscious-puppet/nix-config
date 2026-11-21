-- Neovim windows and Rex panes share focus/move/resize/close keys:
-- https://github.com/pankrashin/vim-rex-navigator (symlinked via home-manager)
local system = require("system")

local navigator = system.home() .. "/.local/share/rex/plugins/vim-rex-navigator/rex"
if system.is_dir(navigator) then
  package.path = navigator .. "/?.lua;" .. package.path
end

-- A missing plugin must not abort the rest of the config.
local loaded, err = pcall(function()
  require("vim-rex-navigator").setup({
    focus_left = "ctrl+h",
    focus_down = "ctrl+j",
    focus_up = "ctrl+k",
    focus_right = "ctrl+l",
    -- move:    shift+opt+cmd+left/right/up/down
    -- resize:  ctrl+opt+cmd+left/right/up/down
    -- close:   cmd+w
  })
end)
if not loaded then
  rex.log("warn", "init.lua: vim-rex-navigator is not loaded: " .. tostring(err))
end

require("project-session")
require("floating-pane")
