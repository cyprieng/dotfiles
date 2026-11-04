-- Helpers around the rex CLI, used when Neovim runs in a Rex pane outside tmux
local M = {}

---@return boolean
function M.enabled()
  return vim.env.REX_SESSION ~= nil and vim.env.TMUX == nil
end

---@param args string[]
---@return string|nil stdout, string|nil err
function M.cli(args)
  local res = vim.system(vim.list_extend({ "rex" }, args), { text = true }):wait(2000)
  if res.code ~= 0 then
    return nil, vim.trim(res.stderr or "rex failed")
  end
  return res.stdout
end

---@param args string[]
---@return table|nil, string|nil err
function M.json(args)
  local out, err = M.cli(args)
  if not out then
    return nil, err
  end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok then
    return nil, decoded
  end
  return decoded
end

---Socket path shared with the `nvr` zsh function, scoped to the Rex window (tab)
---@param window_id string
---@return string
function M.socket(window_id)
  return "/tmp/nvim-rex-" .. window_id:gsub("^window:", "") .. ".sock"
end

---Run a command in a floating Rex pane over the current window; it closes when the command exits
---@param command string[]
---@param cwd string
function M.float(command, cwd)
  local args = vim.json.encode({
    bounds = { 0.05, 0.05, 0.9, 0.9 },
    focus = true,
    layout = {
      block = {
        flavor = "com.superlogical.terminal.shell",
        options = { command = command, cwd = cwd },
      },
    },
  })
  local _, err = M.cli({ "api", "call", "-s", vim.env.REX_SESSION, "session.new_layer", args })
  if err then
    vim.notify("Rex float failed: " .. err, vim.log.levels.ERROR)
  end
end

return M
