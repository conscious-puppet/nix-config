-- Constants and helpers shared by the other modules.
local module = {}

module.TERMINAL = "com.superlogical.terminal"
module.SHELL = "com.superlogical.terminal.shell"
module.HOME = os.getenv("HOME") or ""

-- The server starts with a bare system PATH; borrow the login shell's, and
-- fall back to the nix profiles it may not have set up.
local PATH = (function()
  local login = os.getenv("SHELL") or "/bin/zsh"
  local r = rex.exec({ login, "-l", "-c", "/usr/bin/printenv PATH" }, { timeout = 5 })
  if r and r.ok and r.stdout:find("/") then
    return (r.stdout:gsub("%s+$", ""))
  end
  local user = os.getenv("USER") or module.HOME:match("([^/]+)/*$")
  return table.concat({
    "/etc/profiles/per-user/" .. user .. "/bin",
    module.HOME .. "/.nix-profile/bin",
    module.HOME .. "/.local/state/nix/profiles/profile/bin",
    "/nix/var/nix/profiles/default/bin",
    "/run/current-system/sw/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
  }, ":")
end)()

function module.run(argv, opts)
  opts = opts or {}
  opts.env = opts.env or {}
  opts.env.PATH = PATH
  return rex.exec(argv, opts)
end

-- Like run, but starts the command without waiting; see rex.exec.start.
function module.run_start(argv, opts)
  opts = opts or {}
  opts.env = opts.env or {}
  opts.env.PATH = PATH
  return rex.exec.start(argv, opts)
end

function module.basename(path)
  local trimmed = path:gsub("/+$", "")
  return trimmed:match("([^/]+)$") or trimmed
end

function module.tilde(path)
  local home = module.HOME
  if path == home then
    return "~"
  end
  if path:sub(1, #home + 1) == home .. "/" then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

-- No lfs in Lua 5.1: io.open on "/." succeeds only for directories.
function module.is_dir(path)
  local file = io.open(path .. "/.", "rb")
  if file == nil then
    return false
  end
  file:close()
  return true
end

-- The working directory of a block: the foreground process's, else its
-- OSC 7 file:// URL. A nil block_id means the current block.
function module.block_cwd(block_id)
  local process = rex.block.call(module.TERMINAL, "process", { block_id = block_id })
  local cwd = process and process.foreground and process.foreground.cwd
  if cwd then
    return cwd
  end

  local reported = rex.block.call(module.TERMINAL, "pwd", { block_id = block_id })
  local url = reported and reported.pwd
  if not url then
    return nil
  end

  local path = url:match("^file://[^/]*(/.*)$") or url
  path = path:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  if path ~= "/" then
    path = path:gsub("/+$", "")
  end
  return path
end

-- A terminal block in cwd, running command (nil for the login shell).
function module.terminal_block(command, cwd)
  local options = { cwd = cwd }
  if command and #command > 0 then
    options.command = command
  end
  return rex.layout.block({ flavor = module.SHELL, options = options })
end

return module
