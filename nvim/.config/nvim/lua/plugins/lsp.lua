-- Server-specific settings live in after/lsp/<server>.lua

local servers = {
  "astro",
  "bashls",
  "css_variables",
  "cssls",
  "docker_compose_language_service",
  "dockerls",
  "eslint",
  "gopls",
  "herb_ls",
  "html",
  "intelephense",
  "jsonls",
  "lemminx",
  "lua_ls",
  "marksman",
  "mdx_analyzer",
  "prismals",
  "pyright",
  "somesass_ls",
  "sqlls",
  "tailwindcss",
  "terraformls",
  "vtsls",
  "vue_ls",
  "yamlls",
}

-- Formatters, linters and debug adapters not covered by mason-nvim-dap
local tools = {
  "gofumpt",
  "goimports",
  "js-debug-adapter",
  "markdown-toc",
  "markdownlint-cli2",
  "php-cs-fixer",
  "prettier",
  "ruff",
  "shellcheck",
  "shfmt",
  "sqlfluff",
  "stylua",
  "xmlformatter",
}

return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },

  { "b0o/schemastore.nvim" },

  -- Python venv
  {
    "linux-cultist/venv-selector.nvim",
    ft = "python",
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
      { "<leader>vs", "<cmd>VenvSelect<cr>", desc = "Select venv" },
    },
    init = function()
      -- Auto-activate the project's venv when there is exactly one and none is active yet
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function(ev)
          -- Let venv-selector restore its cached venv first
          vim.defer_fn(function()
            local vs = require("venv-selector")
            if vs.python() then
              return
            end
            local root = vim.fs.root(ev.buf, { "pyproject.toml", "setup.py", "requirements.txt", ".git" })
            local venvs = root and vim.fn.glob(root .. "/*/pyvenv.cfg", true, true) or {}
            if #venvs == 1 then
              vs.activate_from_path(vim.fs.dirname(venvs[1]) .. "/bin/python")
            end
          end, 500)
        end,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "mason-org/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(servers), tools),
        auto_update = true,
      })
      require("mason-lspconfig").setup({ automatic_enable = servers })
      -- Managed by mise, not Mason
      vim.lsp.enable("ruby_lsp")

      vim.diagnostic.config({
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = { border = "rounded" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
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
    end,
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup()
      vim.diagnostic.config({ virtual_text = false })
    end,
  },
}
