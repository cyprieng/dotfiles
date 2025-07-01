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
      copilot_model = "gpt-4.1",
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
            model = "gpt-4.1",
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = "gpt-4.1",
          },
        },
        cmd = {
          adapter = {
            name = "copilot",
            model = "gpt-4.1",
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",

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
