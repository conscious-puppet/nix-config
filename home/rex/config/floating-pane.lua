-- cmd+enter (Return): open a floating pane, or hide/show the one already open.

local function active_window(view)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == view.active_window_id then
      return window
    end
  end
end

local function has_floating_pane(window)
  for _, layer in ipairs(window.layers or {}) do
    if layer.kind == "floating" then
      return true
    end
  end
  return false
end

local function toggle(ctx)
  local view, err = rex.session.view({ session_id = ctx.session_id })
  if view == nil then
    error(err, 0)
  end

  local window = active_window(view)
  if window == nil then
    error("the session has no active window", 0)
  end

  if has_floating_pane(window) then
    rex.client.queue("pane.minimize_floating", {})
  else
    rex.client.queue("pane.new_floating", {})
  end
end

rex.action({
  name = "toggle_floating_pane",
  title = "Toggle Floating Pane",
  category = "Pane",
  keywords = "floating pane window scratchpad show hide toggle open new",
  run = toggle,
})
rex.bind("cmd+enter", "toggle_floating_pane")
