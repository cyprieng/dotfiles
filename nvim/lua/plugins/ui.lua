return {
  -- lazy.nvim
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        sections = {
          { section = "header" },
          {
            pane = 2,
            section = "terminal",
            cmd = "echo ${(U)$(whoami)} | figlet",
            height = 5,
            padding = 1,
          },
          { section = "keys", gap = 1, padding = 1 },
          { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
          { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          {
            pane = 2,
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --rename",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = "startup" },
        },
      },
    },
  },

  -- Override neotree config
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        commands = {
          -- Override delete to use trash instead of rm
          delete = function(state)
            local path = state.tree:get_node().path
            vim.fn.system({ "trash", vim.fn.fnameescape(path) })
            require("neo-tree.sources.manager").refresh(state.name)
          end,
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
      -- stylua: ignore
      { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
    },
    opts = function()
      local opts = {
        bottom = {
          {
            ft = "noice",
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end,
          },
          {
            ft = "lazyterm",
            title = "LazyTerm",
            size = { height = 0.4 },
            filter = function(buf)
              return not vim.b[buf].lazyterm_cmd
            end,
          },
          "Trouble",
          { ft = "qf", title = "QuickFix" },
          {
            ft = "help",
            size = { height = 20 },
            -- don't open help files in edgy that we're editing
            filter = function(buf)
              return vim.bo[buf].buftype == "help"
            end,
          },
          { title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
          { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
          {
            ft = "toggleterm",
            size = { height = 0.3 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == "" and vim.o.columns < 250
            end,
          },
        },
        left = {
          { title = "Neotest Summary", ft = "neotest-summary" },
          -- "neo-tree",
        },
        right = {
          {
            ft = "toggleterm",
            size = { width = 0.25 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == "" and vim.o.columns > 250
            end,
          },
          { title = "Grug Far", ft = "grug-far", size = { width = 0.4 } },
        },
        keys = {
          -- increase width
          ["<C-S-Right>"] = function(win)
            win:resize("width", 2)
          end,
          -- decrease width
          ["<C-S-Left>"] = function(win)
            win:resize("width", -2)
          end,
          -- increase height
          ["<C-S-Up>"] = function(win)
            win:resize("height", 2)
          end,
          -- decrease height
          ["<C-S-Down>"] = function(win)
            win:resize("height", -2)
          end,
        },
      }

      if LazyVim.has("neo-tree.nvim") then
        local pos = {
          filesystem = "left",
          buffers = "top",
          git_status = "right",
          document_symbols = "bottom",
          diagnostics = "bottom",
        }
        local sources = LazyVim.opts("neo-tree.nvim").sources or {}
        for i, v in ipairs(sources) do
          table.insert(opts.left, i, {
            title = "Neo-Tree " .. v:gsub("_", " "):gsub("^%l", string.upper),
            ft = "neo-tree",
            filter = function(buf)
              return vim.b[buf].neo_tree_source == v
            end,
            pinned = true,
            open = function()
              vim.cmd(("Neotree show position=%s %s dir=%s"):format(pos[v] or "bottom", v, LazyVim.root()))
            end,
          })
        end
      end

      for _, pos in ipairs({ "top", "bottom", "left", "right" }) do
        opts[pos] = opts[pos] or {}
        table.insert(opts[pos], {
          ft = "trouble",
          filter = function(_buf, win)
            return vim.w[win].trouble
              and vim.w[win].trouble.position == pos
              and vim.w[win].trouble.type == "split"
              and vim.w[win].trouble.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        })
      end
      return opts
    end,
  },
}
