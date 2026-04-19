local map = vim.keymap.set

-- Terminal
map("t", "<Esc>", "<C-\\><C-n>")

-- Fuzzy finder
map("n", "<leader>ff", "<cmd>FzfLua files<cr>")
map("n", "<leader>fg", "<cmd>FzfLua live_grep<cr>")
map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>")
map("n", "<leader>fh", "<cmd>FzfLua helptags<cr>")

-- File explorer
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>")

-- Format
map("n", "<leader>cf", function()
	require("conform").format()
end)

-- Diagnostics
map("n", "<leader>d", vim.diagnostic.open_float)
map("n", "[d", vim.diagnostic.goto_prev)
map("n", "]d", vim.diagnostic.goto_next)

-- Git hunks
map("n", "]h", "<cmd>Gitsigns next_hunk<cr>")
map("n", "[h", "<cmd>Gitsigns prev_hunk<cr>")
map("n", "<leader>hs", "<cmd>Gitsigns stage_hunk<cr>")
map("n", "<leader>hr", "<cmd>Gitsigns reset_hunk<cr>")
map("n", "<leader>hu", "<cmd>Gitsigns undo_stage_hunk<cr>")
map("n", "<leader>hp", "<cmd>Gitsigns preview_hunk<cr>")
map("n", "<leader>hb", "<cmd>Gitsigns blame_line<cr>")
map("n", "<leader>hd", "<cmd>Gitsigns diffthis<cr>")

-- Buffer tabs
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>")
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>")
map("n", "<leader>x", "<cmd>bdelete<cr>")
