-- Listen on a tmux / Rex window-scoped socket for remote control (skip in nested neovim)
if vim.env.TMUX and not vim.env.NVIM then
  local window_id = vim.fn.system("tmux display-message -p -t \"$TMUX_PANE\" '#{window_id}'"):gsub("%s+", "")
  pcall(vim.fn.serverstart, "/tmp/nvim-tmux-" .. window_id .. ".sock")
elseif require("config.rex").enabled() and not vim.env.NVIM then
  vim.system({ "rex", "whoami", "--json" }, { text = true }, function(res)
    local ok, whoami = pcall(vim.json.decode, res.stdout or "")
    if res.code == 0 and ok and whoami.window_id then
      vim.schedule(function()
        pcall(vim.fn.serverstart, require("config.rex").socket(whoami.window_id))
      end)
    end
  end)
end

-- Leader must be set before plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Options
vim.opt.ruler = false
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.mousemoveevent = true
vim.opt.showmode = false
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.sessionoptions = "buffers,curdir,folds,globals,help,tabpages,winsize,terminal"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.scrolloff = 10
vim.opt.startofline = true

-- Scheduled because the clipboard provider slows down startup
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Folding
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "0"

vim.filetype.add({
  extension = { mdx = "markdown.mdx" },
})

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
}, {
  checker = { enabled = true, notify = false },
})

require("config.keymaps")
require("config.autocmds")
require("config.tab_names").setup()
