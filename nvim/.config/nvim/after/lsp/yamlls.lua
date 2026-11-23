return {
  settings = {
    yaml = {
      -- Built-in schemaStore must be off for schemastore.nvim; empty url avoids a TypeError in yamlls
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
}
