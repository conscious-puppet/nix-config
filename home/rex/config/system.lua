local M = {}

function M.home()
  return os.getenv("HOME") or ""
end

-- Nix profile bin dirs, most specific first.
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

-- Reads a byte: io.open alone also succeeds on directories.
function M.is_file(path)
  local file = io.open(path, "rb")
  if file == nil then
    return false
  end
  local byte = file:read(1)
  file:close()
  return byte ~= nil
end

-- No lfs in Lua 5.1: io.open on "/." succeeds only for directories.
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

return M

