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
        rainbow_delimiters = true,
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
      source_selector = {
        winbar = true,
        statusline = false,
      },
      window = {
        mappings = {
          ["<space>"] = false,
          ["s"] = false,
          ["|"] = "open_vsplit",
          ["oa"] = "avante_add_files",
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        commands = {
          -- Override delete to use trash instead of rm
          delete = function(state)
            local path = state.tree:get_node().path
            vim.fn.system({ "trash", vim.fn.fnameescape(path) })
            require("neo-tree.sources.manager").refresh(state.name)
          end,

          -- Add file to avante
          avante_add_files = function(state)
            local node = state.tree:get_node()
            local filepath = node:get_id()
            local relative_path = require("avante.utils").relative_path(filepath)

            local sidebar = require("avante").get()

            local open = sidebar:is_open()
            -- ensure avante sidebar is open
            if not open then
              require("avante.api").ask()
              sidebar = require("avante").get()
            end

            sidebar.file_selector:add_selected_file(relative_path)

            -- remove neo tree buffer
            if not open then
              sidebar.file_selector:remove_selected_file("neo-tree filesystem [1]")
            end
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
          size = { width = 0.15, height = 0.7 },
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
        -- Ignore notifications for img-clip
        {
          filter = {
            event = "notify",
            find = "Content is not an image",
          },
          opts = { skip = true },
        },
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

  -- Bufferline
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    after = "catppuccin",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<leader>bs", "<Cmd>BufferLinePick<CR>", desc = "Pick buffer" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
    opts = {
      highlights = {
        buffer_visible = { fg = "#C6D0F5", bg = "#303546", bold = true, italic = true },
        separator_visible = { bg = "#303546", fg = "#191C26" },
      },
      options = {
        separator_style = "slant",
        close_command = function(n)
          Snacks.bufdelete(n)
        end,
        right_mouse_command = function(n)
          Snacks.bufdelete(n)
        end,
        diagnostics = "none",
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
        },
        hover = {
          enabled = true,
          delay = 50,
          reveal = { "close" },
        },
        custom_filter = function(buf_number, _)
          if
            vim.bo[buf_number].buftype ~= "terminal"
            and vim.bo[buf_number].buftype ~= "quickfix"
            and vim.bo[buf_number].buftype ~= "nofile"
          then
            return true
          else
            return false
          end
        end,
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)

      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
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
