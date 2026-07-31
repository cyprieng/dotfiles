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
  mermaid = {
    theme = "forest",
    scale = 3,
    width = 2800,
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

-- Separate cache + higher mmdc settings: inline cache is too small for fullscreen.
local fullscreen_renderer_options = {
  mermaid = {
    theme = "forest",
    scale = 6,
    width = 6400,
  },
  plantuml = {
    charset = "utf-8",
  },
  d2 = {
    theme_id = 1,
    scale = 2,
  },
  gnuplot = {
    theme = "dark",
    size = "2400,1800",
  },
}

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
      return diagram, integration
    end
  end
end

local function wait_for_job(job_id, callback)
  if not job_id then
    callback()
    return
  end

  local timer = vim.loop.new_timer()
  if not timer then
    callback()
    return
  end

  timer:start(0, 100, vim.schedule_wrap(function()
    if vim.fn.jobwait({ job_id }, 0)[1] == -1 then
      return
    end
    if timer:is_active() then
      timer:stop()
    end
    if not timer:is_closing() then
      timer:close()
    end
    callback()
  end))
end

local function render_mermaid_fullscreen(source, options)
  vim.fn.mkdir(fullscreen_mermaid_cache, "p")
  local path = vim.fn.resolve(fullscreen_mermaid_cache .. "/" .. vim.fn.sha256(source) .. ".png")

  if vim.fn.filereadable(path) == 1 then
    return { file_path = path }
  end

  if not vim.fn.executable("mmdc") then
    vim.notify("mmdc not found in PATH", vim.log.levels.ERROR, { title = "Diagram" })
    return nil
  end

  local tmpsource = vim.fn.tempname()
  vim.fn.writefile(vim.split(source, "\n"), tmpsource)

  local cmd = { "mmdc", "-i", tmpsource, "-o", path }
  if options.theme then
    vim.list_extend(cmd, { "-t", options.theme })
  end
  if options.scale then
    vim.list_extend(cmd, { "-s", tostring(options.scale) })
  end
  if options.width then
    vim.list_extend(cmd, { "--width", tostring(options.width) })
  end
  if options.height then
    vim.list_extend(cmd, { "--height", tostring(options.height) })
  end

  local job_id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      local msg = table.concat(data, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
      if msg ~= "" then
        vim.notify("Mermaid render failed:\n" .. msg, vim.log.levels.ERROR, { title = "Diagram" })
      end
    end,
  })

  return { file_path = path, job_id = job_id }
end

local function render_fullscreen(diagram, integration)
  local renderer = nil
  for _, r in ipairs(integration.renderers) do
    if r.id == diagram.renderer_id then
      renderer = r
      break
    end
  end
  if not renderer then
    return nil
  end

  local options = fullscreen_renderer_options[renderer.id] or {}
  if renderer.id == "mermaid" then
    return render_mermaid_fullscreen(diagram.source, options)
  end

  return renderer.render(diagram.source, options)
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
  local bufnr = vim.api.nvim_get_current_buf()
  local diagram, integration = get_diagram_at_cursor(bufnr)
  if not diagram then
    vim.notify("No diagram at cursor", vim.log.levels.INFO, { title = "Diagram" })
    return
  end

  vim.notify("Rendering fullscreen " .. diagram.renderer_id .. " diagram...", vim.log.levels.INFO, {
    timeout = 8000,
  })

  local result = render_fullscreen(diagram, integration)
  if not result then
    return
  end

  wait_for_job(result.job_id, function()
    if vim.fn.filereadable(result.file_path) == 0 then
      vim.notify("Diagram file not found: " .. result.file_path, vim.log.levels.ERROR, { title = "Diagram" })
      return
    end
    show_in_tab(diagram, result.file_path)
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
