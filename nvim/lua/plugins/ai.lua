return {
  -- Github copilot plugin
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    opts = {
      suggestion = {
        suggestion = { enabled = false },
        panel = { enabled = false },
      },
      copilot_model = "gemini-2.5-pro",
    },
    config = function()
      require("copilot").setup({
        copilot_node_command = os.getenv("HOME") .. "/.asdf/installs/nodejs/23.7.0/bin/node",
      })
    end,
  },

  {
    "olimorris/codecompanion.nvim",
    opts = {
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "gemini-2.5-pro",
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = "gemini-2.5-pro",
          },
        },
        cmd = {
          adapter = {
            name = "copilot",
            model = "gemini-2.5-pro",
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",

      -- Better diff
      {
        "echasnovski/mini.diff",
        config = function()
          local diff = require("mini.diff")
          diff.setup({
            -- Disabled by default
            source = diff.gen_source.none(),
          })
        end,
      },

      -- Image pasting
      {
        "HakonHarnes/img-clip.nvim",
        opts = {
          filetypes = {
            codecompanion = {
              prompt_for_file_name = false,
              template = "[Image]($FILE_PATH)",
              use_absolute_path = true,
            },
          },
        },
      },
    },
  },
}
