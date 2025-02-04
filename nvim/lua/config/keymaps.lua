local map = vim.keymap.set
local Snacks = require("snacks")

-- Toggle UI windows
map("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm", remap = true })
map("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Neotree", remap = true })
map("n", "<leader>cc", "<cmd>CopilotChatToggle<cr>", { desc = "Github copilot", remap = true })
map("n", "<leader>cq", function()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end, { desc = "Github copilot current file", remap = true })

-- Git
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open git diff", remap = true })
map("n", "<leader>gH", "<cmd>Telescope git_bcommits<cr>", { desc = "Open file git history", remap = true })

-- Exit terminal insert mode
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Window navigation
map("n", "<leader><Right>", "<C-w><Right>", { desc = "Go to right window", remap = true })
map("n", "<leader><Left>", "<C-w><Left>", { desc = "Go to left window", remap = true })
map("n", "<leader><Up>", "<C-w><Up>", { desc = "Go to upper window", remap = true })
map("n", "<leader><Down>", "<C-w><Down>", { desc = "Go to lower window", remap = true })

-- Start/end of line
-- Map Ctrl-A (sent by Cmd+Left) to first non-blank character
vim.keymap.set("n", "<C-a>", "^", { noremap = true })
vim.keymap.set("i", "<C-a>", "<C-o>^", { noremap = true })
vim.keymap.set("v", "<C-a>", "^", { noremap = true })

-- Map Ctrl-E (sent by Cmd+Right) to end of line
vim.keymap.set("n", "<C-e>", "$", { noremap = true })
vim.keymap.set("i", "<C-e>", "<C-o>$", { noremap = true })
vim.keymap.set("v", "<C-e>", "$", { noremap = true })

-- Word navigation
map("n", "<ESC>b", "b", { noremap = true })
map("n", "<ESC>f", "w", { noremap = true })
map("i", "<ESC>b", "<C-o>b", { noremap = true })
map("i", "<ESC>f", "<C-o>w", { noremap = true })
map("v", "<ESC>b", "b", { noremap = true })
map("v", "<ESC>f", "w", { noremap = true })

-- Word remove
-- Alt + Backspace to delete word backward
vim.keymap.set("n", "<A-BS>", "db", { desc = "Delete word backward" })
vim.keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete word backward" })
vim.keymap.set("c", "<A-BS>", "<C-w>", { desc = "Delete word backward" })

-- Alt + Delete to delete word forward
vim.keymap.set("n", "<A-Del>", "dw", { desc = "Delete word forward" })
vim.keymap.set("i", "<A-Del>", "<C-o>dw", { desc = "Delete word forward" })
vim.keymap.set("c", "<A-Del>", "<C-Del>", { desc = "Delete word forward" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- buffers
map("n", "<A-S-Right>", "<cmd>bnext<cr>", { desc = "Next buffer", remap = true })
map("n", "<A-S-Left>", "<cmd>bprevious<cr>", { desc = "Previous buffer", remap = true })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
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

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

--keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- lazy
map("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

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

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
map("n", "<leader>uI", "<cmd>InspectTree<cr>", { desc = "Inspect Tree" })

-- floating terminal
map("n", "<leader>fT", function() Snacks.terminal() end, { desc = "Terminal (cwd)" })

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
