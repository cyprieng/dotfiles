-- ruby-lsp runs `bundle update` on its composed bundle when .ruby-lsp/last_updated
-- is older than 4h, bumping project gems (e.g. rubocop) past Gemfile.lock, and has
-- no option to disable it. Pinning last_updated in the future prevents it.
-- To force a full re-setup: `rm -rf .ruby-lsp/`.
return {
  cmd = function(dispatchers, config)
    local root = config.root_dir or vim.uv.cwd()
    local dir = root .. "/.ruby-lsp"
    vim.fn.mkdir(dir, "p")
    os.remove(dir .. "/needs_update")
    vim.fn.writefile({ "2099-01-01T00:00:00Z" }, dir .. "/last_updated")
    -- Managed by mise, not Mason
    return vim.lsp.rpc.start({ "mise", "x", "--", "ruby-lsp" }, dispatchers, { cwd = root })
  end,
  init_options = {
    addonSettings = {
      ["Ruby LSP Rails"] = { enablePendingMigrationsPrompt = false },
    },
  },
}
