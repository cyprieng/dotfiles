-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm", remap = true })

vim.keymap.set("n", "<leader>ac", "<cmd>Codeium Chat<cr>", { desc = "Open codeium chat", remap = true })

-- Git
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open git diff", remap = true })
vim.keymap.set("n", "<leader>gH", "<cmd>Telescope git_bcommits<cr>", { desc = "Open file git history", remap = true })

-- Exit terminal insert mode
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Window navigation
vim.keymap.set("n", "<A-Right>", "<C-w><Right>", { desc = "Go to right window", remap = true })
vim.keymap.set("n", "<A-Left>", "<C-w><Left>", { desc = "Go to left window", remap = true })
vim.keymap.set("n", "<A-Up>", "<C-w><Up>", { desc = "Go to upper window", remap = true })
vim.keymap.set("n", "<A-Down>", "<C-w><Down>", { desc = "Go to lower window", remap = true })

-- Buffer navigation
vim.keymap.set("n", "<A-S-Right>", "<cmd>bnext<cr>", { desc = "Next buffer", remap = true })
vim.keymap.set("n", "<A-S-Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer", remap = true })
