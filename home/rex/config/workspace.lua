-- Sessions and projects. The project picker reads a cached list that a
-- detached fd scan keeps warm, so it opens instantly; the cache refreshes
-- whenever the picker is used, and a folder can first appear one press after
-- it was created.
local util = require("util")

local module = {}

-- A project is a dir with a .git entry anywhere under the roots below, plus
-- their direct children and FLAT_ROOTS (non-git dirs/containers).
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

local home = util.HOME

local function roots()
  local found = {}
  for _, root in ipairs(RECURSIVE_ROOTS) do
    local path = home .. "/" .. root
    if util.is_dir(path) then
      found[#found + 1] = path
    end
  end
  return found
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
-- it (.git itself can't be excluded here), matching worktrees' .git file
-- too. Strip /.git and any trailing slash to get the project path. No
-- --follow: it dragged fd through the nix store via home-manager symlinks
-- (3x slower) and found nothing new.
local function marked_argv()
  return { "fd", "-0", "-I", "--hidden", "--prune", "^\\.git$", unpack(excludes(true)) }
end

-- Direct children cover non-git dirs and containers of repos; --follow
-- keeps symlinked children such as ~/.config/nvim listed.
local function tops_argv()
  return { "fd", "-0", "-I", "--type", "d", "--hidden", "--follow", "--max-depth", "1", unpack(excludes(false)) }
end

-- NUL-separated paths can include newlines; %z is Lua's NUL pattern.
local function split_nul(output)
  local paths = {}
  for path in output:gmatch("([^%z]+)%z?") do
    paths[#paths + 1] = path
  end
  return paths
end

-- Picker rows from the two result lists, deduped and sorted.
local function rows_from(marked, tops)
  local rows = {}
  local function add(path)
    path = path:gsub("/+$", "")
    if path == "" or rows[path] ~= nil then
      return
    end
    local parent = path:match("^(.*)/[^/]+$") or path
    rows[path] = { id = path, title = util.basename(path), subtitle = util.tilde(parent), icon = "folder" }
  end

  for _, path in ipairs(marked) do
    add((path:gsub("/%.git/*$", "")))
  end
  for _, path in ipairs(tops) do
    add(path)
  end
  for _, root in ipairs(FLAT_ROOTS) do
    if util.is_dir(home .. "/" .. root) then
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

-- The picker can't be filled while it shows, so the list is cached and a
-- detached fd scan refreshes it: started when the config loads, restarted
-- every time the picker opens, and polled into the cache on the next open.
local cached_rows = nil
local inflight = nil

local function scan_start()
  if inflight ~= nil then
    return
  end
  local paths = roots()
  if #paths == 0 then
    return
  end
  -- detach keeps fd running after this action returns; the timeout guards
  -- against a hung filesystem.
  local function start(argv)
    for _, root in ipairs(paths) do
      argv[#argv + 1] = "--search-path"
      argv[#argv + 1] = root
    end
    return util.run_start(argv, { detach = true, timeout = 30 })
  end
  inflight = { marked = start(marked_argv()), tops = start(tops_argv()) }
  if inflight.marked == nil or inflight.tops == nil then
    inflight = nil
  end
end

-- Poll the background scan; once both searches finished, replace the cache.
-- seconds > 0 waits that long for a scan that just started (the first
-- picker after the config loaded). A failed scan keeps the old cache.
local function scan_collect(seconds)
  local scan = inflight
  if scan == nil then
    return
  end
  local marked = scan.marked:wait(seconds or 0)
  local tops = scan.tops:wait(seconds or 0)
  if marked == nil or tops == nil then
    return
  end
  inflight = nil
  if not marked.ok or not tops.ok then
    local failed = not marked.ok and marked or tops
    local why = failed.stderr:gsub("%s+$", "")
    rex.log("warn", "project scan failed" .. (why ~= "" and (": " .. why) or ""))
    return
  end
  cached_rows = rows_from(split_nul(marked.stdout), split_nul(tops.stdout))
end

-- Scan synchronously; only used before the first background scan finishes.
local function scan_sync()
  local paths = roots()
  if #paths == 0 then
    return {}
  end
  local function search(argv)
    for _, root in ipairs(paths) do
      argv[#argv + 1] = "--search-path"
      argv[#argv + 1] = root
    end
    local res, err = util.run(argv)
    if res == nil then
      return nil, "fd did not run (" .. tostring(err) .. "); add it to home.packages to find projects"
    end
    if not res.ok then
      local why = res.stderr:gsub("%s+$", "")
      return nil, why ~= "" and why or ("fd exited with status " .. res.code)
    end
    return split_nul(res.stdout)
  end

  local marked, err = search(marked_argv())
  if marked == nil then
    return nil, err
  end
  local tops
  tops, err = search(tops_argv())
  if tops == nil then
    return nil, err
  end
  return rows_from(marked, tops)
end

local function sessions()
  local list, err = rex.call("session.list", {})
  if list == nil then
    error(err, 0)
  end
  return list.sessions or {}
end

-- Open the session called label in dir, creating it if needed.
local function open(label, dir)
  for _, session in ipairs(sessions()) do
    if session.label == label then
      rex.client.queue("session.select", { session_id = session.session_id })
      return
    end
  end

  local created, err = rex.call("session.create", {
    label = label,
    initial_windows = {
      { layout = util.terminal_block(nil, dir) },
    },
  })
  if created == nil then
    error(err, 0)
  end
  rex.client.queue("session.select", { session_id = created.session_id })
end

-- Current session's cwd: action pane, then active window's focused pane, then
-- the first pane in that window reporting a cwd.
local function session_cwd(ctx)
  local cwd = util.block_cwd(ctx.block_id)
  if cwd ~= nil then
    return cwd
  end

  local function layout_cwd(node)
    if node == nil then
      return nil
    end
    if node.block_id ~= nil then
      return util.block_cwd(node.block_id)
    end
    return layout_cwd(node.split.before) or layout_cwd(node.split.after)
  end

  local view = rex.session.view({})
  if view == nil then
    return nil
  end
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then
      cwd = util.block_cwd(window.focused_block_id)
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

rex.action({
  name = "new_session_here",
  title = "New Session Here",
  category = "Session",
  keywords = "new session here current directory duplicate fork",
  run = function(ctx)
    local all = sessions()
    local current
    for _, session in ipairs(all) do
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
    for _, session in ipairs(all) do
      used[session.label] = true
    end
    local number = 1
    while used[("%s-%d"):format(current, number)] do
      number = number + 1
    end
    return open(("%s-%d"):format(current, number), session_cwd(ctx) or util.HOME)
  end,
})

rex.action({
  name = "project_session",
  title = "New Project Session…",
  category = "Session",
  keywords = "project folder directory picker session work dev open",
  run = function()
    -- Commit a finished background scan; on the first picker after the
    -- config loaded, give the scan it started a moment to land.
    scan_collect(0)
    if cached_rows == nil and inflight ~= nil then
      scan_collect(5)
    end
    local rows = cached_rows
    if rows == nil then
      local err
      rows, err = scan_sync()
      if rows == nil then
        error(err, 0)
      end
      cached_rows = rows
    end
    if #rows == 0 then
      error("no folders found under " .. table.concat(RECURSIVE_ROOTS, ", "))
    end
    if #rows > 2000 then -- rex.ui.pick's display cap
      error(("too many folders to pick from (%d)"):format(#rows))
    end
    scan_start() -- warm the cache for the next picker while this one is open

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
    return open(util.basename(dir), dir)
  end,
})

-- Warm the cache while the server is starting, so the first picker is
-- instant too.
scan_start()

return module
