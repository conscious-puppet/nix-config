-- Focus, move, resize and close Neovim windows and Rex panes with the same
-- keys: https://github.com/pankrashin/vim-rex-navigator
-- The source is the flake-pinned copy symlinked to ~/src/vim-rex-navigator.
local system = require("system")

local navigator = system.home() .. "/src/vim-rex-navigator/rex"
if system.is_dir(navigator) then
  package.path = navigator .. "/?.lua;" .. package.path
end

-- A missing or broken copy should cost only these keys, not the whole
-- configuration: when a configuration fails to load, Rex keeps the last one
-- that did.
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

-- cmd+n: pick a project folder with Rex's own picker.
require("project-session")

-- Every Rex app setting, and the action that pushes them to the app.
require("settings")

-- Apply those settings to the running app on every load, so `rex config
-- reload` is enough after editing them. The push needs a client to name, and a
-- configuration file has none, so it runs in a separate `rex do` process. Its
-- path has to be absolute: launchd starts the server with PATH set to
-- /usr/bin:/bin:/usr/sbin:/sbin, not with a shell's PATH.
--
-- The rex command is not on that PATH either. The app keeps it inside its
-- server bundle, under the same directory on every Mac, and puts that
-- directory in REX_BIN_DIR for the terminals it opens. This process runs
-- detached with its output discarded; apply-settings.lua keeps anything that
-- went wrong in ~/Library/Logs/Rex/settings.log.
local support = system.home() .. "/Library/Application Support/com.superlogical.rex/RexServer"
local command_dirs = {
  support .. "/Versions/Current/Rex Server.app/Contents/MacOS",
  support .. "/CLI",
}
local bin_dir = os.getenv("REX_BIN_DIR")
if bin_dir ~= nil and bin_dir ~= "" then
  table.insert(command_dirs, 1, bin_dir)
end

local cli = system.find_program("rex", command_dirs)
local script = system.script_dir() .. "/apply-settings.lua"
if cli == nil then
  rex.log("warn", "init.lua: not applying settings: the rex command was not found")
elseif not system.is_file(script) then
  rex.log("warn", "init.lua: not applying settings: " .. script .. " is missing")
else
  rex.exec.start({ cli, "do", script }, {
    detach = true,
    stdout = false,
    stderr = false,
  })
end
