local status_ok, lean = pcall(require, "lean")
if not status_ok then
  return
end

lean.setup({
  -- lean specific mappings, on top of the generic lsp
  mappings = true,
})
