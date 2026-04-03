local ufo_handler = function(virtText, lnum, endLnum, width, truncate)
  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0
  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)
      -- str width returned from truncate() may less than 2nd argument, need padding
      if curWidth + chunkWidth < targetWidth then
        suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
      end
      break
    end
    curWidth = curWidth + chunkWidth
  end
  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end

return {
  -- Auto pair
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },

  -- Automatically add closing tags for HTML and JSX
  {
    "windwp/nvim-ts-autotag",
    opts = {},
  },

  -- Diff view
  {
    "sindrets/diffview.nvim",
    config = function()
      -- Monkey-patch FilePanel:update_components() to persist collapsed directory state across refreshes.
      -- The collapsed state lives on component contexts (DirData), not on tree nodes,
      -- because flatten_dirs creates new DirData copies in create_comp_schema().
      local FilePanel = require("diffview.scene.views.diff.file_panel").FilePanel

      local function collect_collapsed_from_comp(comp_struct)
        local state = {}
        if not comp_struct or not comp_struct.comp then return state end
        comp_struct.comp:deep_some(function(comp)
          if comp.name == "directory" and comp.context and comp.context.collapsed then
            state[comp.context.path] = true
          end
          return false
        end)
        return state
      end

      local function restore_collapsed_on_comp(comp_struct, state)
        if not comp_struct or not comp_struct.comp or not next(state) then return end
        comp_struct.comp:deep_some(function(comp)
          if comp.name == "directory" and comp.context and state[comp.context.path] then
            comp.context.collapsed = true
          end
          return false
        end)
      end

      -- Save collapsed state on every toggle so it survives tree rebuilds
      local orig_set_item_fold = FilePanel.set_item_fold
      function FilePanel:set_item_fold(item, open)
        orig_set_item_fold(self, item, open)
        -- Persist current state after fold change
        if self.components then
          ---@diagnostic disable-next-line: inject-field
          self._collapsed_state = {
            conflicting = collect_collapsed_from_comp(self.components.conflicting and self.components.conflicting.files),
            working = collect_collapsed_from_comp(self.components.working and self.components.working.files),
            staged = collect_collapsed_from_comp(self.components.staged and self.components.staged.files),
          }
        end
      end

      -- After update_components rebuilds everything, restore saved state
      local orig_update_components = FilePanel.update_components
      function FilePanel:update_components()
        orig_update_components(self)
        if self._collapsed_state and self.components then
          restore_collapsed_on_comp(self.components.conflicting and self.components.conflicting.files, self._collapsed_state.conflicting or {})
          restore_collapsed_on_comp(self.components.working and self.components.working.files, self._collapsed_state.working or {})
          restore_collapsed_on_comp(self.components.staged and self.components.staged.files, self._collapsed_state.staged or {})
        end
      end
    end,
  },

  -- Toggle terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true,
    opts = {
      auto_scroll = false,
    },
  },

  -- gitsigns
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true, -- Shows git blame for current line
      update_debounce = 1000,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
        update_debounce = 2000,
      },

      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gitsigns.nav_hunk("next")
          end
        end, { desc = "Jump to next git [c]hange" })

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gitsigns.nav_hunk("prev")
          end
        end, { desc = "Jump to previous git [c]hange" })

        -- Actions
        -- visual mode
        map("v", "<leader>hs", function()
          gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "git [s]tage hunk" })
        map("v", "<leader>hr", function()
          gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "git [r]eset hunk" })
        -- normal mode
        map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
        map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
        map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
        map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
        map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
        map("n", "<leader>hb", gitsigns.blame_line, { desc = "git [b]lame line" })
        map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
        map("n", "<leader>hD", function()
          gitsigns.diffthis("@")
        end, { desc = "git [D]iff against last commit" })
        -- Toggles
      end,
    },
  },

  -- Image preview
  {
    "3rd/image.nvim",
    opts = {
      tmux_show_only_in_active_window = true,
    },
  },

  -- Trouble
  {
    "folke/trouble.nvim",
    opts = {
      focus = true,
      win = {
        position = "bottom",
        size = 0.3,
      },
    },
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },


  -- Replace
  {
    "MagicDuck/grug-far.nvim",
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open({
            prefills = {
              search = vim.fn.expand("<cword>"),
              paths = vim.fn.getcwd(),
            },
          })
        end,
        desc = "Replace",
      },
    },
  },

  -- Better folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    opts = {
      fold_virt_text_handler = ufo_handler,
    },
  },

  -- Better yank
  {
    "gbprod/yanky.nvim",
    opts = {},
  },

  -- Color highlight
  {
    "brenoprata10/nvim-highlight-colors",
    event = "VeryLazy",
    config = function()
      require("nvim-highlight-colors").setup({
        render = "virtual",
        enable_tailwind = true,
      })
    end,
  },

  -- Markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown" },
    },
    ft = { "markdown" },
  },

  -- Rainbow delimiters
  { "HiPhish/rainbow-delimiters.nvim", event = "VeryLazy" },

  -- flash
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    vscode = true,
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },


  -- Auto detect indent
  { "tpope/vim-sleuth" },

  -- SwaggerPreview
  {
    "vinnymeller/swagger-preview.nvim",
    cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
    build = "npm i",
    config = true,
  },

  -- Code annotation generator
  {
    "danymat/neogen",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("neogen").setup({
        enabled = true,
        snippet_engine = "luasnip",
      })

      vim.keymap.set("n", "<leader>cn", ":lua require('neogen').generate()<CR>", {
        noremap = true,
        silent = true,
        desc = "Generate documentation",
      })
    end,
  },
}
