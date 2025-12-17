local claude_pane_id = nil

local function focus_claude_pane()
  if claude_pane_id then
    vim.system({ "tmux", "select-pane", "-t", claude_pane_id })
  end
end

return {
  -- AI sidekick
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = {
          backend = "tmux",
          enabled = true,
          create = "split",
        },
      },
    },
    keys = {
      {
        "<tab>",
        function()
          -- if there is a next edit, jump to it, otherwise apply it if any
          if not require("sidekick").nes_jump_or_apply() then
            return "<Tab>" -- fallback to normal tab
          end
        end,
        expr = true,
        desc = "Goto/Apply Next Edit Suggestion",
      },
      {
        "<c-.>",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle CLI",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").select()
        end,
        -- Or to select only installed tools:
        -- require("sidekick.cli").select({ filter = { installed = true } })
        desc = "Select CLI",
      },
      {
        "<leader>ad",
        function()
          require("sidekick.cli").close()
        end,
        desc = "Detach a CLI Session",
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
          vim.defer_fn(focus_claude_pane, 50)
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
          vim.defer_fn(focus_claude_pane, 50)
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
          vim.defer_fn(focus_claude_pane, 50)
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
          vim.defer_fn(focus_claude_pane, 50)
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<leader>ac",
        function()
          -- Get pane IDs before toggle
          local panes_before_str = vim.fn.system("tmux list-panes -F '#{pane_id}'")
          local panes_before = {}
          for pane_id in panes_before_str:gmatch("[^\r\n]+") do
            panes_before[pane_id] = true
          end

          require("sidekick.cli").toggle({ name = "claude", focus = true })

          -- Wait for new pane to appear
          local max_attempts = 50 -- 5 seconds max
          local attempt = 0
          local timer = vim.uv.new_timer()
          timer:start(100, 100, function()
            attempt = attempt + 1

            vim.system({ "tmux", "list-panes", "-F", "#{pane_id}" }, {}, function(obj)
              vim.schedule(function()
                if obj.code == 0 then
                  -- Find new pane by comparing IDs
                  for pane_id in obj.stdout:gmatch("[^\r\n]+") do
                    if not panes_before[pane_id] then
                      -- Found the new pane, save and focus it
                      claude_pane_id = pane_id
                      vim.system({ "tmux", "select-pane", "-t", pane_id })
                      timer:stop()
                      timer:close()
                      return
                    end
                  end
                end

                -- Timeout
                if attempt >= max_attempts then
                  timer:stop()
                  timer:close()
                end
              end)
            end)
          end)
        end,
        desc = "Sidekick Toggle Claude",
      },
    },
  },
}
