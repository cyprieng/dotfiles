-- Refresh neotree status when leaving a buffer
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  pattern = { "*" },
  group = vim.api.nvim_create_augroup("neovim_update_tree", { clear = true }),
  callback = function()
    -- Check if neotree is open
    local manager = require("neo-tree.sources.manager")
    local renderer = require("neo-tree.ui.renderer")
    local state = manager.get_state("filesystem")
    local window_exists = renderer.window_exists(state)

    -- Refresh if window is open
    if window_exists then
      require("neo-tree.sources.filesystem.commands").refresh(
        require("neo-tree.sources.manager").get_state("filesystem")
      )
    end
  end,
})

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
