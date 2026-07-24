return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    --- Eager-load notifier after setup to avoid lazy vim.notify race
    --- (loop/previous error loading snacks.notifier on first notify).
    config = function(_, opts)
      require("snacks").setup(opts)
      require("snacks.notifier")
    end,
    opts = {
      bigfile = { enabled = true, line_length = 10000 },
      indent = {
        enabled = true,
        scope = {
          char = "▍",
        },
      },
      input = { enabled = true },
      picker = { ui_select = true },
      words = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      dashboard = {
        preset = {
          header = [[
                                                                                 
                   ████ ██████           █████      ██                     
                  ███████████             █████                             
                  █████████ ███████████████████ ███   ███████████   
                 █████████  ███    █████████████ █████ ██████████████   
                █████████ ██████████ █████████ █████ █████ ████ █████   
              ███████████ ███    ███ █████████ █████ █████ ████ █████  
             ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
        },
        sections = {
          { section = "header" },
          { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
          { icon = " ", title = "Recent Files", section = "recent_files", cwd = true, indent = 2, padding = 1 },
          { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
