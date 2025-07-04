local map = vim.keymap.set

local Snacks = require("snacks")

-- Select all
map("n", "<leader>ga", "ggVG", { desc = "Select All" })

-- Toggle UI windows
map("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm", remap = true })

-- Neotree mappings
local function is_neotree_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_buf_get_option(buf, "filetype")
    if ft == "neo-tree" then
      return true
    end
  end
  return false
end

map("n", "<leader>e", function()
  vim.cmd("Neotree source=filesystem toggle")
  if is_neotree_open() then
    vim.cmd("Neotree focus")
  end
end, { desc = "Neotree", remap = true })

map("n", "<leader>bb", function()
  vim.cmd("Neotree source=buffers toggle")
  if is_neotree_open() then
    vim.cmd("Neotree focus source=buffers")
  end
end, { desc = "Neotree buffers" })

-- Git
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open git diff", remap = true })

-- Exit terminal insert mode
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Page up/down
map("n", "<PageUp>", "20k", { noremap = true, silent = true })
map("n", "<PageDown>", "20j", { noremap = true, silent = true })

-- Start/end of line
-- Map Ctrl-A (sent by Cmd+Left) to first non-blank character
map("n", "<C-a>", "^", { noremap = true })
map("i", "<C-a>", "<C-o>^", { noremap = true })
map("v", "<C-a>", "^", { noremap = true })

-- Map Ctrl-E (sent by Cmd+Right) to end of line
map("n", "<C-e>", "$", { noremap = true })
map("i", "<C-e>", "<C-o>$", { noremap = true })
map("v", "<C-e>", "$", { noremap = true })

-- Word navigation
map("n", "<ESC>b", "b", { noremap = true })
map("n", "<ESC>f", "w", { noremap = true })
map("i", "<ESC>b", "<C-o>b", { noremap = true })
map("i", "<ESC>f", "<C-o>w", { noremap = true })
map("v", "<ESC>b", "b", { noremap = true })
map("v", "<ESC>f", "w", { noremap = true })

-- Word remove
-- Alt + Backspace to delete word backward
map("n", "<A-BS>", "db", { desc = "Delete word backward" })
map("i", "<A-BS>", "<C-w>", { desc = "Delete word backward" })
map("c", "<A-BS>", "<C-w>", { desc = "Delete word backward" })

-- Alt + Delete to delete word forward
map("n", "<A-Del>", "dw", { desc = "Delete word forward" })
map("i", "<A-Del>", "<C-o>dw", { desc = "Delete word forward" })
map("c", "<A-Del>", "<C-Del>", { desc = "Delete word forward" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- Move lines with macos alt behavior
map("n", "Ï", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "È", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "Ï", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "È", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "Ï", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "È", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- stylua: ignore start

-- toggle options
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.option("conceallevel",
    { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" })
    :map("<leader>uA")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
if vim.lsp.inlay_hint then
    Snacks.toggle.inlay_hints():map("<leader>uh")
end

map("n", "<leader>.", function()
  require("snacks").scratch()
end, { desc = "Toggle Scratch Buffer" })

map("n", "<leader>S", function()
  require("snacks").scratch.select()
end, { desc = "Select Scratch Buffer" })

-- lazygit
if vim.fn.executable("lazygit") == 1 then
    map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit (cwd" })
    map("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "Lazygit Current File History" })
    map("n", "<leader>gL", function() Snacks.lazygit.log() end, { desc = "Lazygit Log (cwd)" })
end

map("n", "<leader>gb", function() Snacks.git.blame_line() end, { desc = "Git Blame Line" })
map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
    Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false })
end, { desc = "Git Browse (copy)" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- Terminal Mappings
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })

-- windows
map("n", "<leader>w", "<c-w>", { desc = "Windows", remap = true })
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- Folding
map('n', 'zR', require('ufo').openAllFolds)
map('n', 'zM', require('ufo').closeAllFolds)

-- Yanky
map({"n","x"}, "p", "<Plug>(YankyPutAfter)")
map({"n","x"}, "P", "<Plug>(YankyPutBefore)")
map({"n","x"}, "gp", "<Plug>(YankyGPutAfter)")
map({"n","x"}, "gP", "<Plug>(YankyGPutBefore)")
map("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
map("n", "<c-n>", "<Plug>(YankyNextEntry)")

-- Vim / Tmux navigation
map({"t", "i", "n"}, '<S-left>', function()
  local win = require("edgy").get_win()
  if win then
    win:resize("width", -2)
  else
    require('smart-splits').resize_left()
  end
end)
map({"t", "i", "n"}, '<S-down>', function()
  local win = require("edgy").get_win()
  if win then
    win:resize("height", -2)
  else
    require('smart-splits').resize_down()
  end
end)
map({"t", "i", "n"}, '<S-up>', function()
  local win = require("edgy").get_win()
  if win then
    win:resize("height", 2)
  else
    require('smart-splits').resize_up()
  end
end)
map({"t", "i", "n"}, '<S-right>', function()
  local win = require("edgy").get_win()
  if win then
    win:resize("width", 2)
  else
    require('smart-splits').resize_right()
  end
end)

map({"i", "n"}, '<C-h>', '<cmd>:SmartCursorMoveLeft<cr>')
map({"i", "n"}, '<C-j>', '<cmd>:SmartCursorMoveDown<cr>')
map({"i", "n"}, '<C-k>', '<cmd>:SmartCursorMoveUp<cr>')
map({"i", "n"}, '<C-l>', '<cmd>:SmartCursorMoveRight<cr>')

-- For terminal mode we need to exit to normal mode before executing the command otherwise it sometimes move to the wrong window
local function smart_term_move(cmd)
  return function()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
    vim.defer_fn(function()
     vim.cmd(cmd)
    end, 1)
  end
end

map("t", "<C-h>", smart_term_move("SmartCursorMoveLeft"))
map("t", "<C-j>", smart_term_move("SmartCursorMoveDown"))
map("t", "<C-k>", smart_term_move("SmartCursorMoveUp"))
map("t", "<C-l>", smart_term_move("SmartCursorMoveRight"))


-- Code companion
map({ "n", "v" }, "<LocalLeader>a", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })
map("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])
