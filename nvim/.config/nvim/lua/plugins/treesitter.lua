return {
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
}
