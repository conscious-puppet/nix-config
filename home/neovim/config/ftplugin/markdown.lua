vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.textwidth = 78
vim.opt_local.wrap = false -- not needed, since text width is 78
vim.opt_local.conceallevel = 0 -- this breaks the text
vim.opt_local.spell = true

local notes_dir = vim.fn.expand("~/notes")
if vim.fn.expand("%:p"):sub(1, #notes_dir) == notes_dir then
  vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "TextChanged" }, {
    buffer = 0,
    command = "silent! write",
  })
end
