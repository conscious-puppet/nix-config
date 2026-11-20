-- cmd+n: pick a project folder and open a session in it.
--
-- The picker is Rex's own: rex.ui.pick has the app show a list in the command
-- palette, filters as you type, and returns the id of the row you choose. A
-- prompt pauses the action that asks it, so it only works inside an action's
-- run function. That is why cmd+n is bound to the action's name rather than to
-- a function: a function bound straight to a key can't ask.
--
-- The list is the same recursive search the old fzf picker made: every folder
-- under ~/work, ~/.config and ~/dev, hidden ones included, the noisy ones
-- excluded, and symlinks followed. Nothing assumes a depth, so a project can
-- sit anywhere under those roots. Picking a folder that already has a session
-- shows that session instead of opening a second one with the same name.

local system = require("system")

-- Roots searched recursively (every folder beneath them).
local RECURSIVE_ROOTS = { "work", ".config", "dev" }
-- Added as a single entry each: the folder itself, not its contents.
local FLAT_ROOTS = { "notes", "work", "dev" }
-- Directories the search never enters.
local EXCLUDES = {
  ".git",
  "node_modules",
  ".cache",
  ".npm",
  ".mozilla",
  ".meteor",
  ".nv",
  ".vscode",
  ".cargo",
  ".direnv",
  "target",
  "dist-newstyle",
  ".stack-work",
  "result",
  "__pycache__",
  ".github",
}

local TERMINAL = "com.superlogical.terminal"
local SHELL = "com.superlogical.terminal.shell"

-- Split find's NUL-separated output. Paths may contain newlines, so newlines
-- can't be the separator.
local function split_nul(text)
  local out, start = {}, 1
  while true do
    local at = text:find("\0", start, true)
    if at == nil then
      if start <= #text then
        out[#out + 1] = text:sub(start)
      end
      return out
    end
    out[#out + 1] = text:sub(start, at - 1)
    start = at + 1
  end
end

-- A path relative to the home directory, without the leading slash. The home
-- directory itself maps to "".
local function relative(path)
  local home = system.home()
  if home == "" then
    return path
  end
  if path == home then
    return ""
  end
  local prefix = home .. "/"
  if path:sub(1, #prefix) == prefix then
    return path:sub(#prefix + 1)
  end
  return path
end

-- The ~/-names of the roots, for error messages.
local function root_names()
  local names = {}
  for _, root in ipairs(RECURSIVE_ROOTS) do
    names[#names + 1] = "~/" .. root
  end
  return table.concat(names, ", ")
end

-- Push one directory onto rows, stripping fd's trailing slash.
local function add_row(rows, path)
  path = path:gsub("/+$", "")
  local parent = path:match("^(.*)/[^/]+$") or path
  local under = relative(parent)
  rows[#rows + 1] = {
    id = path,
    title = path:match("[^/]+$"),
    subtitle = under == "" and "~" or ("~/" .. under),
    icon = "folder",
  }
end

-- One row per directory the search finds, with the folder that holds it as
-- the subtitle. RECURSIVE_ROOTS are searched depth-first; FLAT_ROOTS are added
-- as a single entry each (the folder itself, not its contents).
--
-- Returns the rows, and why there are none when something is missing.
local function items()
  local fd = system.find_program("fd", system.profile_bin_dirs())
  if fd == nil then
    return {}, "fd was not found; add it to home.packages to find projects"
  end

  -- hidden folders included, these names pruned, symlinks followed, NUL
  -- separated so paths with newlines survive. fd appends a trailing "/" to
  -- directory entries; add_row strips it before computing the row's name.
  local argv = { fd, "-0", "-I", "--type", "d", "--hidden", "--follow" }
  for _, name in ipairs(EXCLUDES) do
    argv[#argv + 1] = "--exclude"
    argv[#argv + 1] = name
  end

  local searched = false
  for _, root in ipairs(RECURSIVE_ROOTS) do
    local path = system.home() .. "/" .. root
    if system.is_dir(path) then
      argv[#argv + 1] = "--search-path"
      argv[#argv + 1] = path
      searched = true
    end
  end

  local rows = {}
  if searched then
    local res, err = rex.exec(argv)
    if res == nil then
      return {}, err
    end
    if not res.ok then
      local why = res.stderr:gsub("%s+$", "")
      return {}, why ~= "" and why or ("fd exited with status " .. res.code)
    end
    for _, path in ipairs(split_nul(res.stdout)) do
      add_row(rows, path)
    end
  end

  for _, root in ipairs(FLAT_ROOTS) do
    local path = system.home() .. "/" .. root
    if system.is_dir(path) then
      add_row(rows, path)
    end
  end

  -- rex.ui.pick refuses a list with a repeated id, and one folder can be
  -- reached through two roots when a symlink joins them, so keep the first row
  -- per path.
  local seen, unique = {}, {}
  for _, row in ipairs(rows) do
    if seen[row.id] == nil then
      seen[row.id] = true
      unique[#unique + 1] = row
    end
  end

  table.sort(unique, function(a, b)
    if a.subtitle ~= b.subtitle then
      return a.subtitle:lower() < b.subtitle:lower()
    end
    return a.title:lower() < b.title:lower()
  end)
  return unique
end

-- The session already labelled after the folder, if there is one.
local function session_id_for(label)
  local res, err = rex.call("session.list", {})
  if res == nil then
    error(err, 0)
  end

  for _, session in ipairs(res.sessions or {}) do
    if session.label == label then
      return session.session_id
    end
  end
end

-- A window in dir holding one shell.
local function shell_window(dir)
  return {
    layout = rex.layout.block({
      flavor = SHELL,
      options = { cwd = dir },
    }),
  }
end

-- Show the folder's session, creating it the first time. A session named after
-- the folder is what keeps a second visit from opening a duplicate.
local function open_session(label, dir)
  local session_id = session_id_for(label)

  if session_id == nil then
    local res, err = rex.call("session.create", {
      label = label,
      initial_windows = { shell_window(dir) },
    })
    if res == nil then
      error(err, 0)
    end
    session_id = res.session_id
  end

  -- The app that ran the action performs this, so the new session comes to the
  -- front instead of waiting to be found.
  rex.client.queue("session.select", { session_id = session_id })
  return session_id
end

-- The working directory of a block's foreground process, or the directory the
-- program last reported when its process can't be read.
local function block_cwd(block_id)
  if block_id == nil then
    return nil
  end

  local process = rex.block.call(TERMINAL, "process", { block_id = block_id })
  local cwd = process ~= nil and process.foreground ~= nil and process.foreground.cwd
  if cwd ~= nil then
    return cwd
  end

  -- A program that reports its directory with OSC 7 gives a file:// URL, whose
  -- path is URL-encoded and may end in a slash.
  local reported = rex.block.call(TERMINAL, "pwd", { block_id = block_id })
  local url = reported ~= nil and reported.pwd
  if url == nil then
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

-- The first working directory in a layout tree, depth first.
local function layout_cwd(node)
  if node == nil then
    return nil
  end
  if node.block_id ~= nil then
    return block_cwd(node.block_id)
  end
  if node.split ~= nil then
    return layout_cwd(node.split.before) or layout_cwd(node.split.after)
  end
end

-- Where to open the new session: the action's own pane first, then the active
-- window's focused pane, then any pane in that window that reports a
-- directory.
local function session_cwd(ctx)
  local cwd = block_cwd(ctx.block_id)
  if cwd ~= nil then
    return cwd
  end

  local view = rex.session.view({})
  if view == nil then
    return nil
  end

  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then
      cwd = block_cwd(window.focused_block_id)
      if cwd ~= nil then
        return cwd
      end

      for _, layer in ipairs(window.layers or {}) do
        cwd = layout_cwd(layer.layout)
        if cwd ~= nil then
          return cwd
        end
      end
    end
  end
end

-- Open a new session in the current session's directory, named
-- <current-label>-1, <current-label>-2, etc. (the next available number).
local function new_session_here(ctx)
  local res, err = rex.call("session.list", {})
  if res == nil then
    error(err, 0)
  end

  local current_label
  for _, session in ipairs(res.sessions or {}) do
    if session.session_id == ctx.session_id then
      current_label = session.label
      break
    end
  end
  if current_label == nil then
    error("could not find the current session", 0)
  end

  local number = 1
  while session_id_for(("%s-%d"):format(current_label, number)) ~= nil do
    number = number + 1
  end

  local label = ("%s-%d"):format(current_label, number)
  return open_session(label, session_cwd(ctx) or system.home())
end

-- Show the folder's session.
local function open(dir)
  dir = dir:gsub("/+$", "")
  return open_session(dir:match("[^/]+$") or dir, dir)
end

rex.action({
  name = "new_session_here",
  title = "New Session Here",
  category = "Session",
  keywords = "new session here current directory duplicate fork",
  run = new_session_here,
})

rex.bind("cmd+shift+n", "new_session_here")

rex.action({
  name = "project_session",
  title = "New Project Session…",
  category = "Session",
  keywords = "project folder directory picker session work dev open",
  run = function()
    local rows, why = items()
    if #rows == 0 then
      error(why or ("no folders found under " .. root_names()))
    end
    -- rex.ui.pick shows at most 2,000 items.
    if #rows > 2000 then
      error(("too many folders to pick from (%d)"):format(#rows))
    end

    local dir, reason, detail = rex.ui.pick({
      title = "Open Project",
      placeholder = "Filter folders",
      items = rows,
    })
    if dir == nil then
      -- Closed or timed out: nothing to do, and nothing to report.
      if reason == "cancelled" or reason == "timeout" then
        return
      end
      error("picker " .. reason .. (detail and (": " .. detail) or ""))
    end

    return open(dir)
  end,
})

rex.bind("cmd+n", "project_session")

return { items = items, open = open }
