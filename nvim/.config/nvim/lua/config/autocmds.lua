-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto insert mode when entering in a term buffer
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "term://*",
  group = vim.api.nvim_create_augroup("terminal_insert", { clear = true }),
  callback = function()
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  end,
})

-- Auto close git commit and rebase buffers after saving
vim.api.nvim_create_autocmd("BufWritePost", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.bo[bufnr].filetype
    if ft == "gitcommit" or ft == "gitrebase" then
      vim.defer_fn(function()
        vim.api.nvim_buf_delete(bufnr, {})
      end, 50)
    end
  end,
})

-- Run vim-sleuth on file save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.cmd("silent Sleuth")
  end,
})

-- Save buffer when leaving
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  pattern = "*",
  callback = function()
    local bufname = vim.api.nvim_buf_get_name(0)
    local filetype = vim.bo.filetype
    local buftype = vim.bo.buftype
    -- Ignore non-file buffers and kulala response/scratch buffers
    if
      buftype ~= ""
      or bufname == ""
      or bufname:match("^kulala://")
      or filetype == "kulala"
      or filetype == "kulala-scratch"
      or filetype == "http"
      or filetype == "rest"
    then
      return
    end
    if vim.bo.modified and not vim.bo.readonly then
      vim.api.nvim_command("silent update")
    end
  end,
})
