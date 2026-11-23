-- Telescope modules are required inside functions so lazy.nvim can defer loading the plugin

local function focus_preview(prompt_bufnr)
  local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
  local prompt_win = picker.prompt_win
  local previewer = picker.previewer
  local bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
  local winid = previewer.state.winid or vim.fn.win_findbuf(bufnr)[1]
  vim.keymap.set("n", "<Tab>", function()
    vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
  end, { buffer = bufnr })
  vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
end

-- <C-i> toggles gitignored files, per picker
local rg_files = { "rg", "--files", "--hidden", "--color", "never", "-g", "!.git" }
local rg_grep_args = { "--hidden", "-g", "!.git" }
local show_ignored = {}

local function with_ignored(name, args)
  return show_ignored[name] and vim.list_extend(vim.deepcopy(args), { "--no-ignore" }) or args
end

local function toggle_ignored(name, reopen)
  return function(prompt_bufnr)
    show_ignored[name] = not show_ignored[name]
    require("telescope.actions").close(prompt_bufnr)
    reopen()
  end
end

local function frecency()
  require("frecency.config").setup({
    db_safe_mode = false,
    workspace_scan_cmd = with_ignored("frecency", rg_files),
  })
  require("telescope").extensions.frecency.frecency({
    workspace = "CWD",
    attach_mappings = function(_, map)
      map("i", "<C-i>", toggle_ignored("frecency", frecency))
      return true
    end,
  })
end

-- Buffers in bufferline order
local function buffers()
  local order = {}
  for i, element in ipairs(require("bufferline").get_elements().elements) do
    order[element.id] = i
  end
  require("telescope.builtin").buffers({
    sort_buffers = function(a, b)
      local oa, ob = order[a] or math.huge, order[b] or math.huge
      if oa ~= ob then
        return oa < ob
      end
      return a < b
    end,
    attach_mappings = function(_, map)
      map({ "i", "n" }, "<C-d>", require("telescope.actions").delete_buffer)
      return true
    end,
  })
end

local function git_worktrees()
  local worktrees = {}
  for _, line in ipairs(vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })) do
    local path = line:match("^worktree (.+)")
    if path then
      table.insert(worktrees, { path = path, branch = "(detached)" })
    elseif #worktrees > 0 then
      local branch = line:match("^branch refs/heads/(.+)")
      if branch then
        worktrees[#worktrees].branch = branch
      elseif line == "bare" then
        worktrees[#worktrees].branch = "(bare)"
      end
    end
  end
  return worktrees
end

-- Switch does a global :cd, which neo-tree and telescope follow; open buffers are left untouched
local function worktree_picker()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local cwd = vim.uv.cwd()

  local function finder()
    return require("telescope.finders").new_table({
      results = git_worktrees(),
      entry_maker = function(wt)
        return {
          value = wt,
          ordinal = wt.branch .. " " .. wt.path,
          display = ("%s %-30s %s"):format(wt.path == cwd and "*" or " ", wt.branch, wt.path),
        }
      end,
    })
  end

  local function delete(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    if not selection then
      return
    end
    local path = selection.value.path
    if path == cwd then
      return vim.notify("Cannot delete the current worktree", vim.log.levels.WARN)
    end
    if vim.fn.confirm("Delete worktree " .. path .. "?", "&Yes\n&No", 2) ~= 1 then
      return
    end
    vim.fn.system({ "git", "worktree", "remove", path })
    if vim.v.shell_error ~= 0 then
      vim.fn.system({ "git", "worktree", "remove", "--force", path })
    end
    if vim.v.shell_error ~= 0 then
      return vim.notify("Failed to delete worktree: " .. path, vim.log.levels.ERROR)
    end
    action_state.get_current_picker(prompt_bufnr):refresh(finder(), { reset_prompt = false })
  end

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Git Worktrees",
      finder = finder(),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            vim.fn.chdir(selection.value.path)
            vim.notify("Switched worktree: " .. selection.value.path)
          end
        end)
        map({ "i", "n" }, "<C-d>", delete)
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
    version = false,
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "debugloop/telescope-undo.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-telescope/telescope-frecency.nvim",
    },
    keys = {
      { "<leader>,", buffers, desc = "Buffers" },
      { "<leader>/", "<cmd>Telescope live_grep<cr>", desc = "Grep (Root Dir)" },
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      { "<leader><space>", frecency, desc = "Find Files (Root Dir)" },
      -- find
      { "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
      { "<leader>gh", "<cmd>Telescope git_bcommits_range<cr>", desc = "Line git history" },
      { "<leader>gH", "<cmd>Telescope git_bcommits<cr>", desc = "File git history" },
      { "<leader>gw", worktree_picker, desc = "Git Worktrees" },

      -- search
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sa", "<cmd>Telescope autocommands<cr>", desc = "Auto Commands" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
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
      { "<leader>;", "<cmd>Telescope file_browser<cr>", desc = "File explorer" },
      { "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undo history" },
    },
    config = function()
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")

      require("telescope").setup({
        extensions = {
          undo = {},
          frecency = {
            workspace_scan_cmd = rg_files,
            db_safe_mode = false,
          },
          file_browser = {
            hidden = {
              file_browser = true,
              folder_browser = true,
            },
            respect_gitignore = false,
            no_ignore = true,
          },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          -- open files in the first window of the current tabpage that can host
          -- a file: skip floats and panel windows (neo-tree, terminal, quickfix,
          -- grug-far...), which stickybuf already knows how to identify.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local sticky = require("stickybuf")
            local wins = vim.api.nvim_tabpage_list_wins(0)
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if
                vim.api.nvim_win_get_config(win).relative == ""
                and not sticky.is_pinned(win)
                and not sticky.should_auto_pin(buf)
              then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ["<c-q>"] = function(...)
                return require("trouble.sources.telescope").open(...)
              end,
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
            -- Cut lines to 200 chars: minified files make the previewer very slow
            filetype_hook = function(filepath, bufnr, opts)
              require("telescope.previewers.utils").job_maker({ "cut", "-c", "1-200", filepath }, bufnr, opts)
              vim.schedule(function()
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
            find_command = rg_files,
            mappings = {
              i = {
                ["<C-i>"] = toggle_ignored("find", function()
                  builtin.find_files({ find_command = with_ignored("find", rg_files) })
                end),
              },
            },
          },
          live_grep = {
            additional_args = rg_grep_args,
            mappings = {
              i = {
                ["<C-i>"] = toggle_ignored("grep", function()
                  builtin.live_grep({ additional_args = with_ignored("grep", rg_grep_args) })
                end),
              },
            },
          },
        },
      })

      require("telescope").load_extension("undo")
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("frecency")
    end,
  },
}
