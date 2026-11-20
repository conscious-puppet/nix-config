local M = {}

-- The home directory. Empty when the server somehow has none, which keeps the
-- paths below from failing to build.
function M.home()
  return os.getenv("HOME") or ""
end

-- The directories a Nix profile puts programs in, most specific first. A
-- home-manager switch puts packages in the per-user profile, and single-user
-- Nix puts them in ~/.nix-profile.
function M.profile_bin_dirs()
  local home = M.home()
  local user = os.getenv("USER") or home:match("([^/]+)/*$")

  local dirs = {}
  if user ~= nil and user ~= "" then
    dirs[#dirs + 1] = "/etc/profiles/per-user/" .. user .. "/bin"
  end
  dirs[#dirs + 1] = home .. "/.nix-profile/bin"
  dirs[#dirs + 1] = home .. "/.local/state/nix/profiles/profile/bin"
  dirs[#dirs + 1] = "/nix/var/nix/profiles/default/bin"
  dirs[#dirs + 1] = "/run/current-system/sw/bin"
  return dirs
end

-- Whether path names a readable file. io.open alone also opens directories,
-- so read a byte: reading one from a directory fails.
function M.is_file(path)
  local file = io.open(path, "rb")
  if file == nil then
    return false
  end
  local byte = file:read(1)
  file:close()
  return byte ~= nil
end

-- Whether path is a directory. Appending "/." makes io.open fail for anything
-- that isn't one, which is the directory test Lua 5.1 offers without lfs.
function M.is_dir(path)
  local file = io.open(path .. "/.", "rb")
  if file == nil then
    return false
  end
  file:close()
  return true
end

-- The first readable file called name in dirs, then in this process's PATH.
function M.find_program(name, dirs)
  local function search(dir)
    if dir == nil or dir == "" then
      return nil
    end
    local path = dir .. "/" .. name
    if M.is_file(path) then
      return path
    end
  end

  for _, dir in ipairs(dirs or {}) do
    local found = search(dir)
    if found ~= nil then
      return found
    end
  end

  for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
    local found = search(dir)
    if found ~= nil then
      return found
    end
  end
end

-- The directory holding the Lua file that called this, which is where the
-- files it loads live. Rex loads init.lua and the modules it requires by
-- absolute path, even when ~/.config/rex is a symlink into a checkout.
--
-- This asks about the caller, so call it at load time, not from an action.
function M.script_dir()
  if debug ~= nil and debug.getinfo ~= nil then
    local info = debug.getinfo(2, "S")
    local dir = info ~= nil and info.source ~= nil and info.source:match("^@(.+)/[^/]+$")
    if dir ~= nil then
      return dir
    end
  end
  return M.config_dir()
end

-- Where Rex reads its configuration from: $XDG_CONFIG_HOME/rex, or
-- ~/.config/rex when that variable is unset or empty.
function M.config_dir()
  local base = os.getenv("XDG_CONFIG_HOME")
  if base == nil or base == "" then
    base = M.home() .. "/.config"
  end
  return base .. "/rex"
end

return M
