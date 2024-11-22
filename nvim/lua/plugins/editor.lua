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
    config = true,
    opts = {
      auto_scroll = false,
      on_open = function(term)
        vim.wo.winfixbuf = true
      end,
    },
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
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = cmp.mapping({
        ["<tab>"] = cmp.mapping.confirm({ select = true }),
        ["<esc>"] = cmp.mapping.abort(),
        ["<Down>"] = cmp.mapping.select_next_item(),
        ["<Up>"] = cmp.mapping.select_prev_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
      })
    end,
  },
}
