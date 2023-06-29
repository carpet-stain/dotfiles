if vim.loader then
  vim.loader.enable()
end

require("config.lazy")({
  debug = false,
  defaults = {
    lazy = true,
  },
  performance = {
    cache = {
      enabled = true,
    },
  },
})