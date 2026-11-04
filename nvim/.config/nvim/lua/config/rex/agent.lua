-- Send @path#Ln references to a coding agent running in the current Rex window
local Rex = require("config.rex")

local M = {}

M.enabled = Rex.enabled

---@param fg table foreground process reported by the terminal block
---@return string|nil
local function agent_kind(fg)
  local exe = table.concat({ fg.argv0 or "", fg.path or "", fg.script or "" }, " ")
  if exe:find("cursor-agent", 1, true) then
    return "cursor-agent"
  end
  if exe:find("claude", 1, true) then
    return "claude"
  end
  if exe:find("codex", 1, true) then
    return "codex"
  end
end

---Terminal panes of the tiled layer holding `self`, in reading order (left to right, then top to bottom)
---@param session string
---@param self string
---@return { block_id: string, creator_name: string }[]|nil, string|nil err
local function window_panes(session, self)
  local listing, err = Rex.json({ "window", "ls", "-s", session, "--json" })
  if not listing then
    return nil, err
  end

  for _, window in ipairs(listing.windows) do
    for _, layer in ipairs(window.layers or {}) do
      local rects = {}
      local function walk(node)
        if node.block_id then
          rects[node.block_id] = node.rect
        elseif node.split then
          walk(node.split.before)
          walk(node.split.after)
        end
      end
      if layer.kind == "tiled" and layer.layout then
        walk(layer.layout)
      end

      if rects[self] then
        local panes = vim.tbl_filter(function(b)
          return rects[b.block_id] ~= nil and b.creator_name == "com.superlogical.terminal"
        end, layer.blocks)
        table.sort(panes, function(a, b)
          local ra, rb = rects[a.block_id], rects[b.block_id]
          if math.abs(ra[1] - rb[1]) > 1e-3 then
            return ra[1] < rb[1]
          end
          return ra[2] < rb[2]
        end)
        return panes
      end
    end
  end
  return nil, "current pane not found"
end

---@return { block: string, kind: string, cwd: string|nil, title: string|nil, state: string|nil, index: integer, count: integer }[]|nil, string|nil err
local function find_agents()
  local session, self = vim.env.REX_SESSION, vim.env.REX_BLOCK
  local panes, err = window_panes(session, self)
  if not panes then
    return nil, err
  end

  local agents = {}
  for index, b in ipairs(panes) do
    if b.block_id ~= self then
      local proc = Rex.json({ "block", "call", "-s", session, "-b", b.block_id, "process", "{}" })
      local fg = proc and proc.foreground
      local kind = fg and agent_kind(fg)
      if kind then
        local t = Rex.json({ "block", "call", "-s", session, "-b", b.block_id, "title", "{}" })
        -- agents prefix their title with an activity glyph (✳, spinner…)
        local title = t and t.title and t.title:gsub("^[^%w%s]+%s+", "")
        local status = Rex.json({ "block", "call", "-s", session, "-b", b.block_id, "program_status", "{}" })
        local record = status and status.records and status.records[1]
        table.insert(agents, {
          block = b.block_id,
          kind = kind,
          cwd = fg.cwd,
          title = title,
          state = record and record.state,
          index = index,
          count = #panes,
        })
      end
    end
  end
  return agents
end

---@param what "this"|"file"|"selection"
---@return { file: string, first: integer|nil, last: integer|nil }|nil
local function reference(what)
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then
    return nil
  end
  if what == "file" then
    return { file = file }
  end

  local first, last = vim.fn.line("."), vim.fn.line(".")
  if vim.fn.mode():match("^[vV\22]") then
    first = vim.fn.line("v")
    if first > last then
      first, last = last, first
    end
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  return { file = file, first = first, last = last }
end

---@param ref { file: string, first: integer|nil, last: integer|nil }
---@param cwd string|nil
---@return string
local function format(ref, cwd)
  local path = ref.file
  if cwd and path:sub(1, #cwd + 1) == cwd .. "/" then
    path = path:sub(#cwd + 2)
  end
  local text = "@" .. path
  if ref.first then
    text = text .. "#L" .. ref.first
    if ref.last ~= ref.first then
      text = text .. "-" .. ref.last
    end
  end
  -- trailing space closes the agent's @-mention completion
  return text .. " "
end

local function deliver(agent, ref)
  local session = vim.env.REX_SESSION
  -- focus first: agents can reset their input on the focus-in event, which would drop text sent before it
  Rex.cli({ "focus", "-s", session, agent.block })
  local _, err = Rex.cli({ "send", "-s", session, "-b", agent.block, format(ref, agent.cwd) })
  if err then
    vim.notify("Rex send failed: " .. err, vim.log.levels.ERROR)
  end
end

---@param what "this"|"file"|"selection"
function M.send(what)
  local ref = reference(what)
  if not ref then
    vim.notify("No file to send", vim.log.levels.WARN)
    return
  end

  local agents, err = find_agents()
  if not agents then
    vim.notify("Rex: " .. err, vim.log.levels.ERROR)
    return
  end
  if #agents == 0 then
    vim.notify("No agent in this Rex window", vim.log.levels.WARN)
    return
  end
  if #agents == 1 then
    deliver(agents[1], ref)
    return
  end

  vim.ui.select(agents, {
    prompt = "Send to agent",
    format_item = function(agent)
      local parts = { agent.kind, ("pane %d/%d"):format(agent.index, agent.count) }
      if agent.state then
        table.insert(parts, agent.state)
      end
      if agent.title and agent.title ~= "" then
        table.insert(parts, agent.title)
      end
      if agent.cwd and agent.cwd ~= vim.fn.getcwd() then
        table.insert(parts, vim.fn.fnamemodify(agent.cwd, ":~"))
      end
      return table.concat(parts, "  ")
    end,
  }, function(agent)
    if agent then
      deliver(agent, ref)
    end
  end)
end

return M
