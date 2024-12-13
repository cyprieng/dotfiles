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
  -- autocomplete
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = cmp.mapping({
        ["<enter>"] = cmp.mapping.confirm({ select = false }),
        ["<c-e>"] = cmp.mapping.abort(),
        ["<tab>"] = cmp.mapping.select_next_item(),
        ["<s-tab>"] = cmp.mapping.select_prev_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
      })
      opts.preselect = cmp.PreselectMode.None
      opts.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
      }
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
