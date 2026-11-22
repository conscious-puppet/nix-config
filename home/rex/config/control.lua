-- Keys: Neovim windows and Rex panes share focus/move/resize/close keys
-- through vim-rex-navigator (https://github.com/pankrashin/vim-rex-navigator,
-- symlinked via home-manager), plus this config's session keys.
local util = require("util")

local module = {}

local navigator = util.HOME .. "/.local/share/rex/plugins/vim-rex-navigator/rex"
if util.is_dir(navigator) then
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
  rex.log("warn", "control.lua: vim-rex-navigator is not loaded: " .. tostring(err))
end

-- Sessions and projects (workspace.lua).
rex.bind("cmd+n", "project_session")
rex.bind("cmd+shift+n", "new_session_here")

return module
