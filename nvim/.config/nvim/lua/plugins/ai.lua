return {
  -- AI sidekick
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        enabled = vim.g.enable_github_copilot,
      },
      cli = {
        mux = {
          backend = "tmux",
          enabled = true,
          create = "split",
        },
      },
    },
    config = function(_, opts)
      require("sidekick").setup(opts)

      -- Monkey-patch select format to show tmux window name
      local select = require("sidekick.cli.ui.select")
      local orig_format = select.format
      select.format = function(state, picker)
        local ret = orig_format(state, picker)
        if state.session and state.session.mux_session then
          -- Query tmux for the window name of this pane
          local pane_id = state.session.tmux_pane_id
          if pane_id then
            local result = vim.fn.system({ "tmux", "display-message", "-t", pane_id, "-p", "#{window_name}" })
            local window_name = vim.trim(result or "")
            if window_name ~= "" then
              -- Find the backend bracket and append window name
              for i, part in ipairs(ret) do
                if type(part) == "table" and part[2] == "Special" and part[1]:match("^%[") then
                  ret[i][1] = part[1]:gsub("%]$", ":" .. window_name .. "]")
                  break
                end
              end
            end
          end
        end
        return ret
      end
    end,
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
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>av",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Sidekick Select Prompt",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = vim.g.default_ai_agent or "claude" })
        end,
        desc = "Sidekick Toggle Agent",
      },
    },
  },
}
