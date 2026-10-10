-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Keep using the terminal palette and show Kitty's background (opacity 0.95).

local transparent = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "EndOfBuffer",
  "LineNr",
  "CursorLine",
  "CursorLineNr",
  "FoldColumn",
  "Folded",
  "WinSeparator",
  "VertSplit",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "Pmenu",
  "PmenuSbar",
  "WinBar",
  "WinBarNC",
  "SnacksDashboardNormal",
  "SnacksNormal",
}

local function apply_terminal_theme()
  vim.opt.termguicolors = false
  for _, group in ipairs(transparent) do
    pcall(vim.api.nvim_set_hl, 0, group, { bg = "NONE", ctermbg = "NONE" })
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter", "VimEnter" }, {
  group = vim.api.nvim_create_augroup("terminal_theme_first", { clear = true }),
  callback = apply_terminal_theme,
})
