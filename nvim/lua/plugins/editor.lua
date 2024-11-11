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
  { "akinsho/toggleterm.nvim", version = "*", config = true },
}
