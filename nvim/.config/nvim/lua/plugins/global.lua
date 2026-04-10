return {
  -- TMUX split integration
  { "mrjones2014/smart-splits.nvim", opts = {
    at_edge = "stop",
  } },

  -- Session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    init = function()
      -- Track neo-tree open state continuously
      vim.api.nvim_create_autocmd({ "BufEnter", "BufDelete", "WinClosed" }, {
        callback = function()
          vim.schedule(function()
            vim.g.SessionNeotree = 0
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
                vim.g.SessionNeotree = 1
                break
              end
            end
          end)
        end,
      })

      -- Restore neo-tree after session load
      vim.api.nvim_create_autocmd("SessionLoadPost", {
        callback = function()
          if vim.g.SessionNeotree == 1 then
            vim.schedule(function()
              vim.cmd("Neotree show")
            end)
          end

          -- Force normal mode after restore (terminal buffer triggers startinsert)
          vim.defer_fn(function()
            vim.cmd("stopinsert")
          end, 100)
        end,
      })
    end,
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

  -- Oil file explorer
  {
    "stevearc/oil.nvim",
    opts = {
      delete_to_trash = true,
    },
    lazy = false,
  },

  -- HTTP client
  {
    "mistweaverco/kulala.nvim",
    keys = {
      { "<leader>Rs", desc = "Send request" },
      { "<leader>Ra", desc = "Send all requests" },
      { "<leader>Rb", desc = "Open scratchpad" },
    },
    ft = { "http", "rest" },
    opts = {
      global_keymaps = true,
      global_keymaps_prefix = "<leader>R",
      kulala_keymaps_prefix = "",
      ui = {
        display_mode = "float",
        default_view = "headers_body",
      },
    },
  },
}
