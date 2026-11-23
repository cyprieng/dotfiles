return {
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
}
