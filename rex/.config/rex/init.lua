-- Neovim <-> Rex navigation, same keys as tmux + smart-splits.
-- Ctrl+h/j/k/l move between panes and Shift+arrows resize them; when Neovim is
-- in the foreground the key goes to it, and smart-splits-backend-rex hands off
-- to Rex at the edge of the Neovim layout.

local function is_vim(ctx)
  local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
  local fg = proc and proc.foreground
  if not fg then
    return false
  end
  -- `name` is not always the executable's name, so check `argv0` too
  for _, s in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
    if s:match("^n?vim") then
      return true
    end
  end
  return false
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, function(ctx)
    if is_vim(ctx) then
      return false
    end
    rex.session.focus_direction({ direction = direction })
    return true
  end)
end

-- rex.client.queue only works in actions, so the key is forwarded to Neovim
-- instead of falling through. pane.resize needs Remote Control in the app.
rex.action({
  name = "smart_splits_resize",
  title = "Smart Splits: Resize Pane",
  -- Fire again on key repeat, same as tmux. Covers a Rex pane and Neovim,
  -- which receives the key through pane.send_key on each repeat.
  repeats = true,
  run = function(ctx, args)
    if is_vim(ctx) then
      rex.client.queue("pane.send_key", { key = args.key })
    else
      rex.client.queue("pane.resize", { direction = args.direction, amount = 3 })
    end
  end,
})

for _, direction in ipairs({ "left", "down", "up", "right" }) do
  rex.bind("shift+" .. direction, "smart_splits_resize", { key = "shift+" .. direction, direction = direction })
end

-- Same escape sequences as the Ghostty config; zsh bindkeys and Neovim
-- keymaps expect these exact bytes.
local sequences = {
  ["cmd+left"] = "\27OH", -- Home
  ["cmd+right"] = "\27OF", -- End
  ["alt+left"] = "\27[1;3D", -- word backward
  ["alt+right"] = "\27[1;3C", -- word forward
  ["cmd+z"] = "\31", -- undo
  ["shift+cmd+z"] = "\27e", -- redo
  ["ctrl+shift+up"] = "\27[5~", -- Page Up
  ["ctrl+shift+down"] = "\27[6~", -- Page Down
}

for key, data in pairs(sequences) do
  rex.bind(key, function(ctx)
    return rex.block.call("com.superlogical.terminal", "write", { block_id = ctx.block_id, data = data }) ~= nil
  end)
end
