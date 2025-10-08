-- Command to show a svg image
Image = nil
vim.api.nvim_create_user_command("ImagePreview", function()
  if Image then
    Image:clear()
    Image = nil
  else
    local filepath = vim.api.nvim_buf_get_name(0)
    Image = require("image").from_file(filepath)
    Image:render()
  end
end, {})
