local map = vim.keymap.set
local Snacks = require("snacks")

-- Select all
map("n", "<leader>ga", "ggVG", { desc = "Select All" })

-- Toggle UI windows
map("n", "<leader>t", "<cmd>ToggleTerm<cr>", { desc = "ToggleTerm", remap = true })
map("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "Neotree", remap = true })

-- Git
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open git diff", remap = true })
map("n", "<leader>gH", "<cmd>Telescope git_bcommits<cr>", { desc = "Open file git history", remap = true })

-- Exit terminal insert mode
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { noremap = true, silent = true })

-- Terminal tmux navigation
map({ "t", "i" }, "<C-h>", "<cmd>TmuxNavigateLeft<cr>", { noremap = true, silent = true })
map({ "t", "i" }, "<C-j>", "<cmd>TmuxNavigateDown<cr>", { noremap = true, silent = true })
map({ "t", "i" }, "<C-k>", "<cmd>TmuxNavigateUp<cr>", { noremap = true, silent = true })
map({ "t", "i" }, "<C-l>", "<cmd>TmuxNavigateRight<cr>", { noremap = true, silent = true })

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
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
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

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

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

-- Resize windows
-- Helper function to check if resize is possible in current window
local function can_resize(direction)
    local current_win = vim.api.nvim_get_current_win()
    local window_layout = vim.fn.winlayout()

    -- Recursive function to check if current window is in a resizable split
    local function check_layout(layout, path)
        if layout[1] == "leaf" then
            -- If we found our window
            if layout[2] == current_win then
                -- Check if any part of the path matches our resize direction
                for _, parent_type in ipairs(path) do
                    if parent_type == direction then
                        return true
                    end
                end
            end
            return false
        end

        -- Record the current layout type
        local current_type = layout[1] == "row" and "vertical" or "horizontal"

        -- Add current type to the path
        table.insert(path, current_type)

        -- Check all children
        for _, child in ipairs(layout[2]) do
            if check_layout(child, path) then
                return true
            end
        end

        -- Remove current type from the path
        table.remove(path)

        return false
    end

    return check_layout(window_layout, {})
end

-- Resize windows with fallback to tmux
local function resize_with_fallback(resize_cmd, tmux_direction, resize_direction)
    if can_resize(resize_direction) then
        vim.cmd(resize_cmd)
    else
        local tmux_cmd = string.format("tmux resize-pane -%s 5", tmux_direction)
        vim.fn.system(tmux_cmd)
    end
end

-- Mappings
map("n", "<leader><right>", function()
    resize_with_fallback("vertical resize +2", "R", "vertical")
end, { desc = "Increase window width" })

map("n", "<leader><left>", function()
    resize_with_fallback("vertical resize -2", "L", "vertical")
end, { desc = "Decrease window width" })

map("n", "<leader><up>", function()
    resize_with_fallback("resize +2", "U", "horizontal")
end, { desc = "Increase window height" })

map("n", "<leader><down>", function()
    resize_with_fallback("resize -2", "D", "horizontal")
end, { desc = "Decrease window height" })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
