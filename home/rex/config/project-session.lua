-- cmd+n: pick a project with rex.ui.pick, open its session (or reuse the one
-- named after it). cmd+shift+n: duplicate the current session in its cwd.
-- A project is a dir with a .git entry anywhere under the roots below, plus
-- their direct children and FLAT_ROOTS (non-git dirs/containers).
local system = require("system")

local RECURSIVE_ROOTS = { "work", ".config", "dev" }
local FLAT_ROOTS = { "notes", "work", "dev" }
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

-- Picker rows for every project under the roots. Returns rows, or nil and why.
local function projects()
  local fd = system.find_program("fd", system.profile_bin_dirs())
  if fd == nil then
    return nil, "fd was not found; add it to home.packages to find projects"
  end

  local rows = {}
  local home = system.home()
  local function add(path)
    path = path:gsub("/+$", "")
    if path == "" or rows[path] ~= nil then
      return
    end
    local parent = path:match("^(.*)/[^/]+$") or path
    if parent:sub(1, #home) == home then
      parent = "~" .. parent:sub(#home + 1)
    end
    rows[path] = { id = path, title = path:match("[^/]+$"), subtitle = parent, icon = "folder" }
  end

  local roots = {}
  for _, root in ipairs(RECURSIVE_ROOTS) do
    local path = home .. "/" .. root
    if system.is_dir(path) then
      roots[#roots + 1] = "--search-path"
      roots[#roots + 1] = path
    end
  end
  if #roots == 0 then
    return {}
  end

  -- NUL-separated paths can include newlines; %z is Lua's NUL pattern.
  local function search(argv)
    for _, root in ipairs(roots) do
      argv[#argv + 1] = root
    end
    local res, err = rex.exec(argv)
    if res == nil then
      return nil, err
    end
    if not res.ok then
      local why = res.stderr:gsub("%s+$", "")
      return nil, why ~= "" and why or ("fd exited with status " .. res.code)
    end
    local paths = {}
    for path in res.stdout:gmatch("([^%z]+)%z?") do
      paths[#paths + 1] = path
    end
    return paths
  end

  local function excludes(skip_git)
    local args = {}
    for _, name in ipairs(EXCLUDES) do
      if not (skip_git and name == ".git") then
        args[#args + 1] = "--exclude"
        args[#args + 1] = name
      end
    end
    return args
  end

  -- Repos/worktrees at any depth: --prune lists .git without descending into
  -- it (.git itself can't be excluded here). Strip /.git and any trailing
  -- slash to get the project path.
  local marked, err = search({ fd, "-0", "-I", "--hidden", "--follow", "--prune", "^\\.git$", unpack(excludes(true)) })
  if marked == nil then
    return nil, err
  end
  for _, path in ipairs(marked) do
    add((path:gsub("/%.git/*$", "")))
  end

  -- Direct children cover non-git dirs and containers of repos.
  local tops
  tops, err =
    search({ fd, "-0", "-I", "--type", "d", "--hidden", "--follow", "--max-depth", "1", unpack(excludes(false)) })
  if tops == nil then
    return nil, err
  end
  for _, path in ipairs(tops) do
    add(path)
  end

  for _, root in ipairs(FLAT_ROOTS) do
    if system.is_dir(home .. "/" .. root) then
      add(home .. "/" .. root)
    end
  end

  local unique = {}
  for _, row in pairs(rows) do
    unique[#unique + 1] = row
  end
  table.sort(unique, function(a, b)
    if a.subtitle ~= b.subtitle then
      return a.subtitle:lower() < b.subtitle:lower()
    end
    return a.title:lower() < b.title:lower()
  end)
  return unique
end

-- Open the session called label in dir, creating it if needed.
local function open(label, dir)
  local sessions, err = rex.call("session.list", {})
  if sessions == nil then
    error(err, 0)
  end

  local session_id
  for _, session in ipairs(sessions.sessions or {}) do
    if session.label == label then
      session_id = session.session_id
      break
    end
  end

  if session_id == nil then
    local created
    created, err = rex.call("session.create", {
      label = label,
      initial_windows = {
        { layout = rex.layout.block({ flavor = SHELL, options = { cwd = dir } }) },
      },
    })
    if created == nil then
      error(err, 0)
    end
    session_id = created.session_id
  end

  rex.client.queue("session.select", { session_id = session_id })
end

local function block_cwd(block_id)
  if block_id == nil then
    return nil
  end

  -- Prefer the foreground process cwd; fall back to its OSC 7 file:// URL.
  local process = rex.block.call(TERMINAL, "process", { block_id = block_id })
  local cwd = process ~= nil and process.foreground ~= nil and process.foreground.cwd
  if cwd ~= nil then
    return cwd
  end

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

-- Current session's cwd: action pane, then active window's focused pane, then
-- the first pane in that window reporting a cwd.
local function session_cwd(ctx)
  local cwd = block_cwd(ctx.block_id)
  if cwd ~= nil then
    return cwd
  end

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

local function new_session_here(ctx)
  local sessions, err = rex.call("session.list", {})
  if sessions == nil then
    error(err, 0)
  end

  local current
  for _, session in ipairs(sessions.sessions or {}) do
    if session.session_id == ctx.session_id then
      current = session.label
      break
    end
  end
  if current == nil then
    error("could not find the current session", 0)
  end

  -- Next free <current>-N, then open it in this session's directory.
  local used = {}
  for _, session in ipairs(sessions.sessions or {}) do
    used[session.label] = true
  end
  local number = 1
  while used[("%s-%d"):format(current, number)] do
    number = number + 1
  end
  return open(("%s-%d"):format(current, number), session_cwd(ctx) or system.home())
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
    local rows, err = projects()
    if rows == nil then
      error(err, 0)
    end
    if #rows == 0 then
      error("no folders found under " .. table.concat(RECURSIVE_ROOTS, ", "))
    end
    if #rows > 2000 then -- rex.ui.pick's display cap
      error(("too many folders to pick from (%d)"):format(#rows))
    end

    local dir, reason, detail = rex.ui.pick({
      title = "Open Project",
      placeholder = "Filter folders",
      items = rows,
    })
    if dir == nil then
      if reason == "cancelled" or reason == "timeout" then
        return
      end
      error("picker " .. reason .. (detail and (": " .. detail) or ""))
    end
    return open(dir:match("[^/]+$"), dir)
  end,
})
rex.bind("cmd+n", "project_session")
