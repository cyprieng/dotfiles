-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm", remap = true })
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open git diff", remap = true })
vim.keymap.set("n", "<leader>cc", "<cmd>Codeium Chat<cr>", { desc = "Open codeium chat", remap = true })
