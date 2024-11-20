-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Create an autocommand group
vim.api.nvim_create_augroup("TerminalFix", { clear = true })

-- Set winfixbuf for terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
  group = "TerminalFix",
  pattern = "*",
  command = "setlocal winfixbuf",
})
