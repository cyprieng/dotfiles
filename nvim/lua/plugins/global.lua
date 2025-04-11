return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      {
        "<leader>qs",
        function()
          require("persistence").load()
        end,
        desc = "Restore Session",
      },
      {
        "<leader>qS",
        function()
          require("persistence").select()
        end,
        desc = "Select Session",
      },
      {
        "<leader>ql",
        function()
          require("persistence").load({ last = true })
        end,
        desc = "Restore Last Session",
      },
      {
        "<leader>qd",
        function()
          require("persistence").stop()
        end,
        desc = "Don't Save Current Session",
      },
    },
  },

  -- Link terminal and current neovim instance when opening files
  {
    "willothy/flatten.nvim",
    config = true,
    lazy = false,
    priority = 1001,
  },

  -- Task runner
  {
    "stevearc/overseer.nvim",
    keys = {
      {
        "<leader>ot",
        function()
          require("overseer").toggle()
        end,
        desc = "Toggle Task List",
      },
      {
        "<leader>or",
        function()
          require("overseer").run_template()
        end,
        desc = "Run Task Template",
      },
    },
    opts = {
      task_list = {
        max_height = { 40, 0.5 },
        height = 0.3,
        bindings = {
          ["<C-l>"] = false,
          ["<C-h>"] = false,
          ["<C-k>"] = false,
          ["<C-j>"] = false,
        },
      },
    },
  },
}
