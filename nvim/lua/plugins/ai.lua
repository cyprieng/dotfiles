return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      provider = "copilot",
      copilot = {
        model = "gpt-4.1",
        temperature = 0,
        max_tokens = 8192,
      },
      file_selector = {
        provider = "telescope",
        provider_opts = {
          get_filepaths = function(params)
            local cwd = params.cwd
            local selected_filepaths = params.selected_filepaths
            local cmd = string.format("rg --files --hidden -g '!.git'", vim.fn.fnameescape(cwd))
            local output = vim.fn.system(cmd)
            local filepaths = vim.split(output, "\n", { trimempty = true })
            return vim
              .iter(filepaths)
              :filter(function(filepath)
                return not vim.tbl_contains(selected_filepaths, filepath)
              end)
              :totable()
          end,
        },
      },
      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = true,
        support_paste_from_clipboard = false,
        minimize_diff = true,
        enable_token_counting = true,
      },
    },
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
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
        },
        config = function()
          require("copilot").setup({
            copilot_node_command = os.getenv("HOME") .. "/.asdf/installs/nodejs/23.7.0/bin/node",
          })
        end,
      },
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
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
