return {
  -- Multi cursor
  {
    "mg979/vim-visual-multi",
    branch = "master",
    config = function() end,
    lazy = false,
  },
  -- Diff view
  {
    "sindrets/diffview.nvim",
  },
  -- Toggle terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        auto_scroll = false,
      })
      -- Custom key mapping to exit insert mode
      vim.api.nvim_set_keymap("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })
    end,
  },
  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- Shows git blame for current line
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
        ignore_whitespace = false,
      },
    },
  },
}
