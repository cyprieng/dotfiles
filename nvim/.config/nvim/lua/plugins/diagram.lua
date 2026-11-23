local integrations

local function get_integrations()
  if integrations then
    return integrations
  end
  local markdown_integration = require("diagram.integrations.markdown")
  integrations = {
    markdown_integration,
    vim.tbl_extend("force", markdown_integration, {
      filetypes = { "markdown.mdx" },
    }),
  }
  return integrations
end

local inline_renderer_options = {
  -- No width/height: diagram.nvim passes --width/--height, which mmdc 12 removed
  mermaid = {
    theme = "forest",
    scale = 3,
  },
  plantuml = {
    charset = "utf-8",
  },
  d2 = {
    theme_id = 1,
  },
  gnuplot = {
    theme = "dark",
    size = "800,600",
  },
}

-- diagram.nvim caches by source only, so fullscreen needs its own cache to get a sharper render
local fullscreen_mermaid_options = { theme = "forest", scale = 6 }
local fullscreen_mermaid_cache = vim.fn.stdpath("cache") .. "/diagram-cache/mermaid-fullscreen"

local function get_integration(bufnr)
  local ft = vim.bo[bufnr].filetype
  for _, integration in ipairs(get_integrations()) do
    if vim.tbl_contains(integration.filetypes, ft) then
      return integration
    end
  end
end

local function get_extended_range(bufnr, diagram)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local start_row = diagram.range.start_row
  local end_row = diagram.range.end_row

  for i = start_row, 0, -1 do
    local line = lines[i + 1]
    if line and line:match("^%s*```") then
      start_row = i
      break
    end
  end

  for i = end_row, #lines - 1 do
    local line = lines[i + 1]
    if line and line:match("^%s*```%s*$") then
      end_row = i
      break
    end
  end

  return { start_row = start_row, end_row = end_row }
end

local function get_diagram_at_cursor(bufnr)
  local integration = get_integration(bufnr)
  if not integration then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1

  for _, diagram in ipairs(integration.query_buffer_diagrams(bufnr)) do
    local range = get_extended_range(bufnr, diagram)
    if row >= range.start_row and row <= range.end_row then
      return diagram
    end
  end
end

local function render_mermaid_fullscreen(source, on_done)
  vim.fn.mkdir(fullscreen_mermaid_cache, "p")
  local path = fullscreen_mermaid_cache .. "/" .. vim.fn.sha256(source) .. ".png"
  if vim.fn.filereadable(path) == 1 then
    return on_done(path)
  end
  if vim.fn.executable("mmdc") == 0 then
    return vim.notify("mmdc not found in PATH", vim.log.levels.ERROR, { title = "Diagram" })
  end

  local input = vim.fn.tempname() .. ".mmd"
  vim.fn.writefile(vim.split(source, "\n"), input)
  local o = fullscreen_mermaid_options
  local cmd = { "mmdc", "-i", input, "-o", path, "-t", o.theme, "-s", tostring(o.scale) }
  vim.system(cmd, { text = true }, function(res)
    os.remove(input)
    vim.schedule(function()
      if res.code ~= 0 then
        local err = vim.trim(res.stderr or "")
        return vim.notify("Mermaid render failed:\n" .. err, vim.log.levels.ERROR, { title = "Diagram" })
      end
      on_done(path)
    end)
  end)
end

local function show_in_tab(diagram, file_path)
  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_name(buf, diagram.renderer_id .. " diagram")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  local win_width = vim.api.nvim_win_get_width(win)
  local win_height = vim.api.nvim_win_get_height(win)

  local image = require("image").from_file(file_path, {
    buffer = buf,
    window = win,
    with_virtual_padding = true,
    inline = true,
    x = 0,
    y = 0,
    width = win_width,
    height = win_height,
    max_width_window_percentage = 100,
    max_height_window_percentage = 100,
  })

  if not image then
    vim.notify("Failed to display diagram image", vim.log.levels.ERROR, { title = "Diagram" })
    vim.cmd("tabclose")
    return
  end

  image.ignore_global_max_size = true
  image:render()

  vim.notify("Diagram ready — q/Esc close · o open in Preview", vim.log.levels.INFO, { timeout = 2500 })

  local function close_tab()
    image:clear()
    vim.cmd("tabclose")
  end

  vim.keymap.set("n", "q", close_tab, { buffer = buf, desc = "Close diagram tab" })
  vim.keymap.set("n", "<Esc>", close_tab, { buffer = buf, desc = "Close diagram tab" })
  vim.keymap.set("n", "o", function()
    vim.ui.open(file_path)
  end, { buffer = buf, desc = "Open image with system viewer" })

  vim.api.nvim_create_autocmd("VimResized", {
    buffer = buf,
    callback = function()
      local w = vim.api.nvim_win_get_width(win)
      local h = vim.api.nvim_win_get_height(win)
      image:render({ width = w, height = h })
    end,
  })
end

local function show_fullscreen()
  local diagram = get_diagram_at_cursor(vim.api.nvim_get_current_buf())
  if not diagram then
    return vim.notify("No diagram at cursor", vim.log.levels.INFO, { title = "Diagram" })
  end
  if diagram.renderer_id ~= "mermaid" then
    return vim.notify("Fullscreen only supports mermaid", vim.log.levels.WARN, { title = "Diagram" })
  end

  vim.notify("Rendering fullscreen mermaid diagram...", vim.log.levels.INFO, { timeout = 8000 })
  render_mermaid_fullscreen(diagram.source, function(path)
    show_in_tab(diagram, path)
  end)
end

local function setup_rerender_autocmds()
  local augroup = vim.api.nvim_create_augroup("diagram_rerender", { clear = true })

  local function rerender_markdown()
    vim.schedule(function()
      pcall(function()
        require("diagram").render()
      end)
    end)
  end

  vim.api.nvim_create_autocmd({ "TabEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function(ev)
      local ft = vim.bo[ev.buf].filetype
      if ft == "markdown" or ft == "markdown.mdx" then
        rerender_markdown()
      end
    end,
  })

  vim.api.nvim_create_autocmd("TabClosed", {
    group = augroup,
    callback = rerender_markdown,
  })
end

return {
  "3rd/diagram.nvim",
  ft = { "markdown", "markdown.mdx" },
  config = function()
    require("diagram").setup({
      integrations = get_integrations(),
      renderer_options = inline_renderer_options,
    })

    setup_rerender_autocmds()
  end,
  keys = {
    {
      "<leader>dm",
      show_fullscreen,
      mode = "n",
      ft = { "markdown", "markdown.mdx" },
      desc = "Open diagram in full tab",
    },
  },
}
