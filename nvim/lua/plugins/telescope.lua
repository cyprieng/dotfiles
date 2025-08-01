-- Function to switch between the preview window and the prompt window
local function focus_preview(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local picker = action_state.get_current_picker(prompt_bufnr)
  local prompt_win = picker.prompt_win
  local previewer = picker.previewer
  local bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
  local winid = previewer.state.winid or vim.fn.win_findbuf(bufnr)[1]
  vim.keymap.set("n", "<Tab>", function()
    vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
  end, { buffer = bufnr })
  vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
  -- api.nvim_set_current_win(winid)
end

return {
  -- Fuzzy finder.
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false, -- telescope did only one release, so use HEAD for now
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "debugloop/telescope-undo.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    keys = {
      {
        "<leader>,",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep (Root Dir)" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find Files (Root Dir)" },
      -- find
      {
        "<leader>fb",
        "<cmd>Telescope buffers sort_mru=true sort_lastused=true ignore_current_buffer=true<cr>",
        desc = "Buffers",
      },
      { "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
      { "<leader>gh", "<cmd>Telescope git_bcommits_range<cr>", { desc = "Open file git history", remap = true } },
      { "<leader>gH", "<cmd>Telescope git_bcommits<cr>", { desc = "Open file git history", remap = true } },

      -- search
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
      { "<leader>sc", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader>sC", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
      { "<leader>sD", "<cmd>Telescope diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { "<leader>sH", "<cmd>Telescope highlights<cr>", desc = "Search Highlight Groups" },
      { "<leader>sj", "<cmd>Telescope jumplist<cr>", desc = "Jumplist" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
      { "<leader>sl", "<cmd>Telescope loclist<cr>", desc = "Location List" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
      { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
      { "<leader>sR", "<cmd>Telescope resume<cr>", desc = "Resume" },
      { "<leader>sq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix List" },
      { "<leader>;", ":Telescope file_browser<CR>", desc = "File explorer" },
      {
        "<leader>fu",
        "<cmd>Telescope undo<cr>",
        desc = "undo history",
      },
    },
    config = function()
      local actions = require("telescope.actions")

      local open_with_trouble = function(...)
        return require("trouble.sources.telescope").open(...)
      end

      -- Find files
      local normal_cmd = { "rg", "--files", "--color", "never", "-g", "!.git" }
      local no_ignore_cmd = { "rg", "--files", "--color", "never", "-g", "!.git", "--no-ignore" }
      local use_no_ignore = false
      local function toggle_no_ignore(prompt_bufnr)
        use_no_ignore = not use_no_ignore
        actions.close(prompt_bufnr)
        require("telescope.builtin").find_files({
          find_command = use_no_ignore and no_ignore_cmd or normal_cmd,
          hidden = true,
        })
      end

      -- Live grep
      local normal_grep_args = { "--color=never", "-g", "!.git" }
      local no_ignore_grep_args = { "--color=never", "-g", "!.git", "--no-ignore" }
      local use_no_ignore_grep = false
      local function toggle_no_ignore_grep(prompt_bufnr)
        use_no_ignore_grep = not use_no_ignore_grep
        require("telescope.actions").close(prompt_bufnr)
        require("telescope.builtin").live_grep({
          additional_args = function()
            return use_no_ignore_grep and no_ignore_grep_args or normal_grep_args
          end,
        })
      end

      require("telescope").setup({
        extensions = {
          undo = {},
          file_browser = {
            hidden = {
              file_browser = true,
              folder_browser = true,
            },
            respect_gitignore = false,
            no_ignore = true,
          },
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          },
        },
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          -- open files in the first window that is an actual file.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == "" then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<c-q>"] = open_with_trouble,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
            },
            n = {
              ["q"] = actions.close,
              ["<Tab>"] = focus_preview,
            },
          },
          preview = {
            -- We limit line length to 200 characters otherwise telescope is very slow
            filetype_hook = function(filepath, bufnr, opts)
              local cmd = { "cut", "-c", "1-200", filepath }
              require("telescope.previewers.utils").job_maker(cmd, bufnr, opts)

              -- Set filetype after content is loaded
              vim.schedule(function()
                -- Try to detect filetype from filename
                local ft = vim.filetype.match({ filename = filepath })
                if ft then
                  vim.bo[bufnr].filetype = ft
                end
              end)
            end,
          },
        },
        pickers = {
          find_files = {
            find_command = normal_cmd,
            hidden = true,
            mappings = {
              i = {
                ["<C-i>"] = toggle_no_ignore,
              },
            },
          },
          live_grep = {
            find_command = normal_grep_args,
            hidden = true,
            mappings = {
              i = {
                ["<C-i>"] = toggle_no_ignore_grep,
              },
            },
          },

          buffers = {
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
            },
          },
        },
      })

      -- Load plugins
      require("telescope").load_extension("undo")
      require("telescope").load_extension("fzf")
    end,
  },
}
