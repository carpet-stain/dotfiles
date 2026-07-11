-- Seamless pane navigation across Neovim splits and the Zellij terminal
-- multiplexer. The Ctrl-hjkl binds below only work at a split's edge because
-- zellij/config.kdl forwards those same keys here via the vim-zellij-
-- navigator plugin — see KEYBINDINGS.md for the full chain. Resizing is
-- deliberately NOT wired through here (no Alt-hjkl): Zellij's own Resize
-- mode (Ctrl-n) already owns those keys by default, and a forwarded
-- Alt-hjkl resize was tried and dropped — see KEYBINDINGS.md's "Design
-- decisions" section for why.
return {
  {
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    config = function()
      require("smart-splits").setup()

      vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
      vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
      vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
      vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
    end,
  },
}
