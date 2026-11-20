return {
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        -- Load luvit types when the `vim.uv` word is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },

  -- JSON Schema Store
  { "b0o/schemastore.nvim" },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", config = true },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      -- Python venv
      {
        "linux-cultist/venv-selector.nvim",
        dependencies = {
          "neovim/nvim-lspconfig",
          "nvim-telescope/telescope.nvim",
          {
            "mfussenegger/nvim-dap-python",
            build = {
              type = "builtin",
              copy_directories = {
                "doc",
              },
            },
          },
        },
        opts = {},
        keys = {
          -- Keymap to open VenvSelector to pick a venv.
          { "<leader>vs", "<cmd>VenvSelect<cr>" },
          -- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
          { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
        },
      },
    },
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          local builtin = require("telescope.builtin")

          -- Same keys as Neovim's gr*/gO defaults, shown in telescope; grn/gra stay native
          map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
          map("grd", builtin.lsp_definitions, "[G]oto [D]efinition")
          map("grr", builtin.lsp_references, "[G]oto [R]eferences")
          map("gri", builtin.lsp_implementations, "[G]oto [I]mplementation")
          map("grt", builtin.lsp_type_definitions, "[G]oto [T]ype Definition")
          map("gO", builtin.lsp_document_symbols, "Open Document Symbols")
          map("gW", builtin.lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "eslint" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = event.buf,
              command = "LspEslintFixAll",
            })
          end
        end,
      })

      -- Change diagnostic symbols in the sign column (gutter)
      vim.diagnostic.config({
        signs = true, -- Show signs in the sign column
        underline = true, -- Use underline for diagnostics
        update_in_insert = false, -- Don't update diagnostics in insert mode
        severity_sort = true, -- Sort diagnostics by severity
        float = {
          border = "rounded",
        },
      })

      if vim.g.have_nerd_font then
        local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
        local diagnostic_signs = {}
        for type, icon in pairs(signs) do
          diagnostic_signs[vim.diagnostic.severity[type]] = icon
        end
        vim.diagnostic.config({ signs = { text = diagnostic_signs } })
      end

      -- Enable the following language servers
      local servers = {
        astro = {},
        bashls = {},
        css_variables = {},
        cssls = {},
        docker_compose_language_service = {},
        dockerls = {},
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
            format = true,
          },
        },
        gopls = {},
        html = {},
        intelephense = {},
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        marksman = {},
        mdx_analyzer = {},
        prismals = {},
        pyright = {
          settings = {
            python = {
              venvPath = ".venv",
              pythonPath = ".venv/bin/python",
            },
          },
        },
        somesass_ls = {},
        sqlls = {},
        tailwindcss = {},
        terraformls = {},
        vue_ls = {},
        vtsls = {},
        lemminx = {},
        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                -- You must disable built-in schemaStore support if you want to use
                -- this plugin and its advanced options like `ignore`.
                enable = false,
                -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        },
        herb_ls = {},
      }

      -- VUE config
      local vue_language_server_path = vim.fn.stdpath("data")
        .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
        configNamespace = "typescript",
      }
      local vtsls_config = {
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
            },
          },
        },
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      }

      local vue_ls_config = {
        on_init = function(client)
          client.handlers["tsserver/request"] = function(_, result, context)
            local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
            if #clients == 0 then
              vim.notify("Could not found `vtsls` lsp client, vue_lsp would not work without it.", vim.log.levels.ERROR)
              return
            end
            local ts_client = clients[1]

            local param = unpack(result)
            local id, command, payload = unpack(param)
            ts_client:exec_cmd({
              title = "vue_request_forward", -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
              command = "typescript.tsserverRequest",
              arguments = {
                command,
                payload,
              },
            }, { bufnr = context.bufnr }, function(_, r)
              local response_data = { { id, r.body } }
              ---@diagnostic disable-next-line: param-type-mismatch
              client:notify("tsserver/response", response_data)
            end)
          end
        end,
      }
      vim.lsp.config("vtsls", vtsls_config)
      vim.lsp.config("vue_ls", vue_ls_config)

      -- Ensure the servers and tools above are installed
      require("mason").setup()
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        "shfmt",
        "shellcheck",
        "stylua",
        "prettier",
        "eslint",
        "php-debug-adapter",
        "php-cs-fixer",
        "delve",
        "goimports",
        "gofumpt",
        "js-debug-adapter",
        "debugpy",
        "sqlfluff",
        "markdown-toc",
        "markdownlint-cli2",
        "ruff",
        "xmlformatter",
      })
      require("mason-tool-installer").setup({
        ensure_installed = ensure_installed,
        auto_update = true,
      })
      require("mason-lspconfig").setup({
        automatic_enable = ensure_installed,
      })

      -- Setup all servers
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      for server_name, server_config in pairs(servers) do
        local server = vim.tbl_deep_extend("force", {}, server_config)
        -- This handles overriding only values explicitly passed
        -- by the server configuration above. Useful when disabling
        -- certain features of an LSP (for example, turning off formatting for ts_ls)
        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
        vim.lsp.config(server_name, server)
      end

      -- ruby_lsp: managed by mise, not Mason.
      -- cmd as function to access config.root_dir: neovim defaults cmd CWD to its
      -- own CWD (not root_dir), so last_updated and needs_update were written to
      -- the wrong directory, silently breaking the update-prevention mechanism.
      -- Wrapper prevents the 4h `bundle update prism rbs ruby-lsp debug` cascade
      -- that updates project gems (e.g. rubocop) beyond Gemfile.lock constraints.
      -- To force a full re-setup: `rm -rf .ruby-lsp/`.
      vim.lsp.config("ruby_lsp", {
        cmd = function(dispatchers, config)
          local root = config.root_dir or vim.uv.cwd()
          return require("vim.lsp.rpc").start({
            "sh",
            "-c",
            'mkdir -p .ruby-lsp && rm -f .ruby-lsp/needs_update && echo "2099-01-01T00:00:00Z" > .ruby-lsp/last_updated && exec mise x -- ruby-lsp',
          }, dispatchers, { cwd = root })
        end,
        capabilities = capabilities,
        init_options = {
          addonSettings = {
            ["Ruby LSP Rails"] = {
              enablePendingMigrationsPrompt = false,
            },
          },
        },
      })
      vim.lsp.enable("ruby_lsp")
    end,
  },

  -- Autoformat
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>ff",
        function()
          require("conform").format({ timeout_ms = 5000, lsp_format = "fallback" })
        end,
        mode = "",
        desc = "[F]ormat buffer",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = { timeout_ms = 5000, lsp_format = "fallback" },
      formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofumpt" },
        python = { "ruff_format" },
        php = { "php_cs_fixer" },
        eruby = { "herb_format" },
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
        xml = { "xmlformatter" },
        svg = { "xmlformatter" },
        sql = { "sqlfluff" },
        mysql = { "sqlfluff" },
        plsql = { "sqlfluff" },
        markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
        astro = { "prettier" },
        css = { "prettier" },
        graphql = { "prettier" },
        handlebars = { "prettier" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        less = { "prettier" },
        scss = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        vue = { "prettier" },
        yaml = { "prettier" },
      },
      formatters = {
        herb_format = { command = "herb-format", stdin = true },
        sqlfluff = { args = { "format", "--dialect=ansi", "-" } },
      },
    },
  },

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

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local TS = require("nvim-treesitter")

      local ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "query",
        "typescript",
        "vim",
        "vimdoc",
        "astro",
        "css",
        "pug",
        "vue",
        "ruby",
        "embedded_template",
        "python",
        "go",
        "gomod",
        "php",
        "json",
        "yaml",
        "toml",
        "tsx",
        "sql",
        "hcl",
        "terraform",
        "dockerfile",
        "regex",
        "http",
        "scss",
        "gitcommit",
        "git_rebase",
      }

      -- Install missing parsers
      local installed = TS.get_installed()
      local to_install = vim.tbl_filter(function(lang)
        return not vim.tbl_contains(installed, lang)
      end, ensure_installed)
      if #to_install > 0 then
        TS.install(to_install)
      end

      -- Enable highlight on FileType, skip large files
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          local max_filesize = 500 * 1024 -- 500 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
          if ok and stats and stats.size > max_filesize then
            return
          end
          if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Diagnostics
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup()
      vim.diagnostic.config({ virtual_text = false }) -- Disable default virtual text
    end,
  },
}
