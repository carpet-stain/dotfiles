vim.api.nvim_create_user_command("FormatToggle", function(_)
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  local state = vim.g.disable_autoformat and "disabled" or "enabled"
  vim.notify("Auto-save " .. state)
end, {
  desc = "Toggle autoformat-on-save",
  bang = true,
})
