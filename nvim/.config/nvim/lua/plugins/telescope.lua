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
end

-- Buffer search based on bufferline.nvim to have the same order and filters
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")

-- Helper to get or create a highlight group for a specific color
local function get_icon_hl(color)
  local hl_name = "TelescopeDevicon" .. color:gsub("#", "")
  if vim.fn.hlexists(hl_name) == 0 then
    vim.api.nvim_set_hl(0, hl_name, { fg = color })
  end
  return hl_name
end

-- Custom Telescope picker for bufferline buffers
-- Shows buffers in the same order and with the same filters as bufferline
local function bufferline_picker(opts)
  opts = opts or {}

  -- Load required dependencies
  local devicons = require("nvim-web-devicons")
  local ok, bufferline = pcall(require, "bufferline")
  if not ok then
    vim.notify("bufferline.nvim is not available", vim.log.levels.ERROR)
    return
  end

  -- Get buffer list from bufferline
  local bufferline_buffers = bufferline.get_elements and bufferline.get_elements().elements or {}
  if not bufferline_buffers or vim.tbl_isempty(bufferline_buffers) then
    vim.notify("No buffers found in bufferline", vim.log.levels.INFO)
    return
  end

  -- Create entry for each buffer with metadata and display formatting
  local function make_entry(entry)
    local bufnr = entry.id
    local fullpath = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(fullpath, ":t")
    if filename == "" then
      filename = "[No Name]"
    end

    -- Get file metadata
    local relpath = fullpath ~= "" and vim.fn.fnamemodify(fullpath, ":.") or ""
    local ft_icon, ft_color = devicons.get_icon_color(filename)
    local modified = vim.bo[bufnr].modified
    local icon_hl = ft_color and get_icon_hl(ft_color) or nil
    local is_current = bufnr == vim.api.nvim_get_current_buf()

    return {
      value = bufnr,
      ordinal = filename .. " " .. relpath, -- Used for fuzzy searching
      filename = filename,
      relpath = relpath,
      icon = ft_icon or "",
      icon_hl = icon_hl,
      modified = modified,
      bufnr = bufnr,
      is_current = is_current,

      -- Define how the entry is displayed in the picker
      display = function(entry2)
        local displayer = entry_display.create({
          separator = " ",
          items = {
            { width = 2 }, -- icon
            { width = nil }, -- filename
            { width = nil }, -- relative path
            { width = 2 }, -- modified indicator
            { width = 6 }, -- buffer number
          },
        })
        return displayer({
          { entry2.icon, entry2.icon_hl },
          { entry2.filename, entry2.is_current and "TelescopeResultsIdentifier" or "" },
          { entry2.relpath ~= "" and "(" .. entry2.relpath .. ")" or "", "Comment" },
          { entry2.modified and "●" or " ", entry2.modified and "TelescopeResultsNumber" or "" },
          { "[" .. entry2.bufnr .. "]", "Comment" },
        })
      end,
    }
  end

  pickers
    .new(opts, {
      prompt_title = "Bufferline Buffers",
      finder = finders.new_table({
        results = bufferline_buffers,
        entry_maker = make_entry,
      }),
      sorter = conf.generic_sorter(opts),

      -- Show buffer contents in preview window
      previewer = require("telescope.previewers").new_buffer_previewer({
        define_preview = function(self, entry, _)
          local bufnr = entry.value
          if vim.api.nvim_buf_is_valid(bufnr) then
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            local ft = vim.bo[bufnr].filetype
            vim.bo[self.state.bufnr].filetype = ft
          end
        end,
      }),

      -- Setup keymaps
      attach_mappings = function(prompt_bufnr, map)
        -- Override default action to switch to selected buffer
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection and selection.value then
            vim.api.nvim_set_current_buf(selection.value)
          end
        end)

        -- Add Ctrl-d to delete the selected buffer
        local delete_buffer = function()
          local selection = action_state.get_selected_entry()
          if not selection or not selection.value then
            return
          end

          local bufnr = selection.value

          -- Delete the buffer using vim command
          -- Bufferline will intercept this and handle it properly
          local success, err = pcall(vim.cmd.bdelete, bufnr)
          if not success then
            vim.notify("Cannot delete buffer: " .. tostring(err), vim.log.levels.WARN)
            return
          end

          -- Refresh the picker after a small delay to allow bufferline to update
          vim.defer_fn(function()
            local current_picker = action_state.get_current_picker(prompt_bufnr)
            if not current_picker then
              return
            end

            -- Get updated buffer list from bufferline
            local new_buffers = bufferline.get_elements and bufferline.get_elements().elements or {}

            -- Close picker if no buffers remain
            if vim.tbl_isempty(new_buffers) then
              actions.close(prompt_bufnr)
              return
            end

            -- Refresh picker with new buffer list
            current_picker:refresh(
              finders.new_table({
                results = new_buffers,
                entry_maker = make_entry,
              }),
              { reset_prompt = false }
            )
          end, 50)
        end

        -- Map Ctrl-d in both insert and normal mode
        map("i", "<C-d>", delete_buffer)
        map("n", "<C-d>", delete_buffer)

        return true
      end,
    })
    :find()
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
        bufferline_picker,
        desc = "Buffers (filtered)",
      },
      { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep (Root Dir)" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find Files (Root Dir)" },
      -- find
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
      local normal_cmd = { "rg", "--hidden", "--files", "--color", "never", "-g", "!.git" }
      local no_ignore_cmd = { "rg", "--hidden", "--files", "--color", "never", "-g", "!.git", "--no-ignore" }
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
      local normal_grep_args = { "--color=never", "--hidden", "-g", "!.git" }
      local no_ignore_grep_args = { "--color=never", "--hidden", "-g", "!.git", "--no-ignore" }
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
            additional_args = normal_grep_args,
            hidden = true,
            mappings = {
              i = {
                ["<C-i>"] = toggle_no_ignore_grep,
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
