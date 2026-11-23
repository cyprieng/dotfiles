return {
  -- Autocompletion
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
        dependencies = {
          {
            "rafamadriz/friendly-snippets",
            config = function()
              require("luasnip.loaders.from_vscode").lazy_load()
            end,
          },
        },
      },
    },
    version = "1.*",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
        ["<C-r>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "cancel", "fallback" },

        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = {
          "select_next",
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },

        ["<Up>"] = {
          function(cmp)
            if cmp.get_selected_item() then
              return cmp.select_prev({ on_ghost_text = true })
            end
          end,
          "fallback",
        },
        ["<Down>"] = {
          function(cmp)
            if cmp.get_selected_item() then
              return cmp.select_next({ on_ghost_text = true })
            end
          end,
          "fallback",
        },
        ["<C-p>"] = {
          function(cmp)
            cmp.select_prev({ on_ghost_text = true })
          end,
          "fallback_to_mappings",
        },
        ["<C-n>"] = {
          function(cmp)
            cmp.select_next({ on_ghost_text = true })
          end,
          "fallback_to_mappings",
        },

        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },

        -- <C-k> is reserved for split navigation
        ["<C-k>"] = false,
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        accept = { auto_brackets = { enabled = true } },
        list = {
          selection = {
            preselect = false,
          },
        },

        -- Highlight colors
        menu = {
          auto_show = true,
          draw = {
            treesitter = { "lsp" },
            components = {
              -- customize the drawing of kind icons
              kind_icon = {
                text = function(ctx)
                  -- default kind icon
                  local icon = ctx.kind_icon
                  -- if LSP source, check for color derived from documentation
                  if ctx.item.source_name == "LSP" then
                    local color_item =
                      require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                    if color_item and color_item.abbr ~= "" then
                      icon = color_item.abbr
                    end
                  end
                  return icon .. ctx.icon_gap
                end,
                highlight = function(ctx)
                  -- default highlight group
                  local highlight = "BlinkCmpKind" .. ctx.kind
                  -- if LSP source, check for color derived from documentation
                  if ctx.item.source_name == "LSP" then
                    local color_item =
                      require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                    if color_item and color_item.abbr_hl_group then
                      highlight = color_item.abbr_hl_group
                    end
                  end
                  return highlight
                end,
              },
            },
          },
        },
      },

      signature = { enabled = true },
      snippets = { preset = "luasnip" },

      sources = {
        default = { "lsp", "path", "snippets" },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
