-- Auto insert mode when entering in a term buffer
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  pattern = "term://*", -- Correspond à tous les buffers de terminal
  group = vim.api.nvim_create_augroup("terminal_insert", { clear = true }),
  callback = function()
    vim.schedule(function()
      vim.cmd("startinsert")
    end)
  end,
})

-- Configuration for automatic updates
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    -- Check if it's a new day
    local last_update = vim.fn.getftime(vim.fn.stdpath("data") .. "/lazy-last-update")
    local current_time = os.time()

    -- If more than 24h have passed since last update
    if current_time - last_update >= 86400 then
      -- Use a timer to ensure Mason is loaded
      vim.defer_fn(function()
        vim.notify("Starting daily updates...")
        vim.cmd("Lazy update")
        vim.cmd("MasonUpdate")
        vim.cmd("MasonToolsUpdate")
        vim.fn.writefile({}, vim.fn.stdpath("data") .. "/lazy-last-update")
      end, 1000)
    end
  end,
})
