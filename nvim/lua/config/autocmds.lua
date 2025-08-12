-- Automatically show diagnostics in a floating window when the cursor is held
local diag_float_winid = nil

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local opts = { focus = false }
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
    for _, diag in ipairs(diagnostics) do
      if diag.message and #diag.message > 80 then -- Only show if message is long
        _, diag_float_winid = vim.diagnostic.open_float(nil, opts)
        return
      end
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
  callback = function()
    if diag_float_winid and vim.api.nvim_win_is_valid(diag_float_winid) then
      vim.api.nvim_win_close(diag_float_winid, true)
      diag_float_winid = nil
    end
  end,
})

-- Ensure cmdheight is not getting resized when resizing the window
vim.api.nvim_create_autocmd({ "VimResized", "BufEnter", "BufWinEnter", "BufLeave", "FocusLost" }, {
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

-- Configuration for automatic updates
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimStarted",
  callback = function()
    -- Get last update time from file
    local last_update = vim.fn.getftime(vim.fn.stdpath("data") .. "/lazy-last-update")
    local current_time = os.time()

    -- If more than 24h have passed since last update
    if current_time - last_update >= 86400 then
      if require("lazy.status").has_updates then
        require("lazy").update({ show = false })
      end
      vim.fn.writefile({}, vim.fn.stdpath("data") .. "/lazy-last-update")
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
