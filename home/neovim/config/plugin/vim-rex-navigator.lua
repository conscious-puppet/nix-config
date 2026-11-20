-- vim-rex-navigator: ctrl+h/j/k/l moves between Neovim windows and, at the
-- edge, to the neighbouring Rex pane. The Rex side binds the same keys.
-- move/resize/close keep the plugin's defaults so both sides match:
--   move:   shift+opt+cmd+left/right/up/down
--   resize: ctrl+opt+cmd+left/right/up/down
--   close:  cmd+w
require("vim-rex-navigator").setup { focus = false }

local opts = { silent = true, desc = "Focus Neighbouring Rex Pane" }
vim.keymap.set({ "n", "v" }, "<C-h>", "<cmd>RexFocusLeft<cr>", opts)
vim.keymap.set({ "n", "v" }, "<C-j>", "<cmd>RexFocusDown<cr>", opts)
vim.keymap.set({ "n", "v" }, "<C-k>", "<cmd>RexFocusUp<cr>", opts)
vim.keymap.set({ "n", "v" }, "<C-l>", "<cmd>RexFocusRight<cr>", opts)
