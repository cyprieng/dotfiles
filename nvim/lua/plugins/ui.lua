local Snacks = require("snacks")

return {
  -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "frappe",
      integrations = {
        blink_cmp = true,
        diffview = true,
        grug_far = true,
        mason = true,
        noice = true,
        overseer = true,
        snacks = {
          enabled = true,
          indent_scope_color = "lavender",
        },
        lsp_trouble = true,
        which_key = true,
      },
    },
    init = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Useful plugin to show you pending keybinds.
  {
    "folke/which-key.nvim",
    event = "VimEnter", -- Sets the loading event to 'VimEnter'
    opts = {
      icons = {
        -- set icon mappings to true if you have a Nerd Font
        mappings = vim.g.have_nerd_font,
        -- If you are using a Nerd Font: set icons.keys to an empty table which will use the
        -- default which-key.nvim defined Nerd Font icons, otherwise define a string table
        keys = vim.g.have_nerd_font and {} or {
          Up = "<Up> ",
          Down = "<Down> ",
          Left = "<Left> ",
          Right = "<Right> ",
          C = "<C-…> ",
          M = "<M-…> ",
          D = "<D-…> ",
          S = "<S-…> ",
          CR = "<CR> ",
          Esc = "<Esc> ",
          ScrollWheelDown = "<ScrollWheelDown> ",
          ScrollWheelUp = "<ScrollWheelUp> ",
          NL = "<NL> ",
          BS = "<BS> ",
          Space = "<Space> ",
          Tab = "<Tab> ",
          F1 = "<F1>",
          F2 = "<F2>",
          F3 = "<F3>",
          F4 = "<F4>",
          F5 = "<F5>",
          F6 = "<F6>",
          F7 = "<F7>",
          F8 = "<F8>",
          F9 = "<F9>",
          F10 = "<F10>",
          F11 = "<F11>",
          F12 = "<F12>",
        },
      },

      -- Document existing key chains
      spec = {
        { "<leader>c", group = "[C]ode", mode = { "n", "x" } },
        { "<leader>d", group = "[D]ocument" },
        { "<leader>r", group = "[R]ename" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
        { "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
      },
    },
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin",
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      tabline = {},
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },

        lualine_c = {
          {
            "diagnostics",
            symbols = {
              error = " ",
              warn = " ",
              hint = " ",
              info = " ",
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        },
        lualine_x = {
          Snacks.profiler.status(),
          {
            function()
              return require("noice").api.status.command.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.command.has()
            end,
            color = function()
              return { fg = Snacks.util.color("Statement") }
            end,
          },
          {
            function()
              return require("noice").api.status.mode.get()
            end,
            cond = function()
              return package.loaded["noice"] and require("noice").api.status.mode.has()
            end,
            color = function()
              return { fg = Snacks.util.color("Constant") }
            end,
          },
          {
            function()
              return "  " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] and require("dap").status() ~= ""
            end,
            color = function()
              return { fg = Snacks.util.color("Debug") }
            end,
          },
          {
            require("lazy.status").updates,
            cond = require("lazy.status").has_updates,
            color = function()
              return { fg = Snacks.util.color("Special") }
            end,
          },
          {
            "diff",
            symbols = {
              added = " ",
              modified = " ",
              removed = " ",
            },
          },
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = {
          function()
            return " " .. os.date("%R")
          end,
        },
      },
    },
  },

  -- Neotree
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      sources = { "filesystem", "buffers" },
      window = {
        mappings = {
          ["s"] = false,
          ["|"] = "open_vsplit",
        },
      },
      use_libuv_file_watcher = true,
      filesystem = {
        commands = {
          -- Override delete to use trash instead of rm
          delete = function(state)
            local path = state.tree:get_node().path
            vim.fn.system({ "trash", vim.fn.fnameescape(path) })
            require("neo-tree.sources.manager").refresh(state.name)
          end,
        },
        follow_current_file = {
          enabled = true,
        },
        filtered_items = {
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          hide_by_name = {
            ".git",
            ".DS_Store",
            "thumbs.db",
          },
          never_show = {},
        },
      },
      buffers = {
        show_unloaded = true,
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)

      -- Watch for file system changes
      local uv = vim.loop
      local refresh_neo_tree = function()
        require("neo-tree.sources.manager").refresh("filesystem")
      end

      local watch_dir = function(path)
        local handle
        handle = uv.new_fs_event()
        uv.fs_event_start(
          handle,
          path,
          {},
          vim.schedule_wrap(function()
            refresh_neo_tree()
          end)
        )
      end

      -- Watch the current working directory
      watch_dir(vim.loop.cwd())

      -- Refresh Neo-tree when leaving terminal mode
      vim.api.nvim_create_autocmd("TermLeave", {
        callback = function()
          vim.defer_fn(function()
            refresh_neo_tree()
          end, 100)
        end,
      })
    end,
  },

  -- Edgy window manager
  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ue",
        function()
          require("edgy").toggle()
        end,
        desc = "Edgy Toggle",
      },
      {
        "<leader>uE",
        function()
          require("edgy").select()
        end,
        desc = "Edgy Select Window",
      },
    },
    opts = {
      left = {
        -- Neo-tree on left
        {
          title = "Neo-Tree",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          size = { width = 0.15, height = 0.7 },
        },
        {
          title = "Neo-Tree Buffers",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "buffers"
          end,
        },
      },

      right = {
        -- Terminal on right for large screen
        {
          title = "Terminal",
          ft = "toggleterm",
          size = { width = 0.25 },
          filter = function()
            return vim.o.columns > 250
          end,
        },
      },

      bottom = {
        -- Terminal at the bottom for small screen
        {
          title = "Terminal",
          ft = "toggleterm",
          size = { height = 0.3 },
          filter = function()
            return vim.o.columns <= 250
          end,
        },
      },
    },
  },

  -- Noice UI replacement
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
            },
          },
          view = "mini",
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
      views = {
        mini = {
          position = {
            row = 0,
          },
        },
      },
    },
  },

  -- UI improvements
  { "stevearc/dressing.nvim" },

  -- Better quickfix
  { "kevinhwang91/nvim-bqf" },

  -- Sticky buffers
  {
    "stevearc/stickybuf.nvim",
    opts = {},
  },

  -- Show buffers name
  {
    "b0o/incline.nvim",
    config = function()
      local helpers = require("incline.helpers")
      local devicons = require("nvim-web-devicons")
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0 },
        },
        hide = {
          cursorline = "focused_win",
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)
          local modified = vim.bo[props.buf].modified
          return {
            ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
            " ",
            { filename, gui = modified and "bold,italic" or "bold" },
            " ",
            guibg = "#44406e",
          }
        end,
      })
    end,
    -- Optional: Lazy load Incline
    event = "VeryLazy",
  },
}
