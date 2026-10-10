-- Terminal theme first: skip LazyVim colorschemes, keep Kitty background.
return {
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.opt.termguicolors = false
      end,
    },
  },
}
