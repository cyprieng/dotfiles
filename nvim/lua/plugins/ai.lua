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

  -- MCP servers
  {
    "ravitemer/mcphub.nvim",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "bundled_build.lua",
    config = function()
      require("mcphub").setup({
        use_bundled_binary = true,
      })
    end,
  },

  -- AI interface
  {
    "olimorris/codecompanion.nvim",
    lazy = true,
    event = "VeryLazy",
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
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            show_result_in_chat = true, -- Show mcp tool results in chat
            make_vars = true, -- Convert resources to #variables
            make_slash_commands = true, -- Add prompts as /slash commands
          },
        },
      },
    },
    init = function()
      require("plugins.ai.extensions.companion-notification").init()
    end,
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
