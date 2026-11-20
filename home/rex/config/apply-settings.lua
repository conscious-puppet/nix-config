-- Push the settings in settings.lua to every connected Rex app.
--
-- init.lua starts this on every configuration load, so `rex config reload`
-- applies the settings to the running app. Run it by hand with:
--
--   rex do ~/.config/rex/apply-settings.lua
--
-- The app performs the settings itself, so it has to accept actions: Remote
-- Control on in its Settings under Server. Without it every call is refused.
--
-- The settings live beside this file, wherever the configuration is installed,
-- so find them from here rather than from ~/.config/rex: REX_CONFIG and
-- XDG_CONFIG_HOME can put the configuration elsewhere.

local system = require("system")

local settings = dofile(system.script_dir() .. "/settings.lua")
local problems = settings.push()

-- The push that init.lua starts runs detached with its output discarded, so
-- leave the last run's problems where they can be found. A clean run removes
-- the file rather than leaving old news behind.
local path = system.home() .. "/Library/Logs/Rex/settings.log"
if #problems == 0 then
  os.remove(path)
  return
end

for _, problem in ipairs(problems) do
  rex.log("warn", "settings: " .. problem)
end

rex.exec({ "/bin/mkdir", "-p", path:match("^(.*)/[^/]+$") })
local file = io.open(path, "w")
if file ~= nil then
  file:write(os.date("%Y-%m-%d %H:%M:%S"), "\n")
  for _, problem in ipairs(problems) do
    file:write("settings: ", problem, "\n")
  end
  file:close()
end
