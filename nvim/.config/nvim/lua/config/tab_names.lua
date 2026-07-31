local M = {}

---@param tabnr number
---@return string
function M.label(tabnr)
  for _, buf in ipairs(vim.fn.tabpagebuflist(tabnr)) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype:match("^Diffview") then
      return "Diffview"
    end
  end

  for _, buf in ipairs(vim.fn.tabpagebuflist(tabnr)) do
    if vim.api.nvim_buf_is_valid(buf) then
      local bufname = vim.api.nvim_buf_get_name(buf)
      if bufname:match(" diagram$") then
        return "Diagram"
      end
    end
  end

  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.tabnr == tabnr and vim.api.nvim_win_is_valid(win.winid) and vim.wo[win.winid].diff then
      local buf = vim.api.nvim_win_get_buf(win.winid)
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
      if fname ~= "" then
        return "Diff · " .. fname
      end
    end
  end

  local buflist = vim.fn.tabpagebuflist(tabnr)
  local winnr = vim.fn.tabpagewinnr(tabnr)
  local bufnr = buflist[winnr]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    if name ~= "" then
      return name
    end
  end

  return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

function M.update()
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local tabnr = vim.api.nvim_tabpage_get_number(tabpage)
    pcall(vim.api.nvim_tabpage_set_var, tabpage, "name", M.label(tabnr))
  end

  if package.loaded["bufferline"] then
    require("bufferline.ui").refresh()
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "TabEnter", "VimEnter", "TabNewEntered", "SessionLoadPost" }, {
    callback = function()
      vim.schedule(M.update)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = { "DiffviewOpen", "DiffviewClose" },
    callback = function()
      vim.schedule(M.update)
    end,
  })
end

return M
