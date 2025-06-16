-- Ensure cmdheight is not getting resized when resizing the window
vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  callback = function()
    vim.defer_fn(function()
      vim.opt.cmdheight = 0
    end, 50)
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
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command("silent update")
    end
  end,
})

-- Smart-splits have an issue where @pane-is-vim is sometimes resetted to 0
-- Ensure it is set to 1 every time we gain focus
vim.api.nvim_create_autocmd("FocusGained", {
  callback = function()
    if vim.env.TMUX then
      vim.fn.jobstart({
        "tmux",
        "set-option",
        "-p",
        "@pane-is-vim",
        "1",
      })
    end
  end,
  desc = "Set tmux @pane-is-vim=1 when Neovim gains focus (only in tmux)",
})
