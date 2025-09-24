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
        extensions = {
          avante = {
            make_slash_commands = true, -- make /slash commands from MCP server prompts
          },
        },
      })
    end,
  },

  -- avante
  {
    "yetone/avante.nvim",
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      provider = "copilot",
      providers = {
        copilot = {
          model = "gpt-4.1",
        },
      },
      input = {
        provider = "snacks",
        provider_opts = {
          -- Additional snacks.input options
          title = "Avante Input",
          icon = " ",
        },
      },
      file_selector = {
        provider = "telescope",
      },
      selector = {
        provider = "telescope",
      },

      -- system_prompt as function ensures LLM always has latest MCP server state
      -- This is evaluated for every message, even in existing chats
      system_prompt = function()
        local hub = require("mcphub").get_hub_instance()
        return hub and hub:get_active_servers_prompt() or ""
      end,
      -- Using function prevents requiring mcphub before it's loaded
      custom_tools = function()
        return {
          require("mcphub.extensions.avante").mcp_tool(),
        }
      end,
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
    },
  },
}
