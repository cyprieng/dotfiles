require("lspconfig").volar.setup({
  on_attach = function(client, bufnr)
    -- Disable formatting for volar
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
})
