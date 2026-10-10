-- CSS / HTML language servers + formatters (JS/TS via typescript extra)
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {},
        html = {},
        -- eslint optional; mason will install when available
      },
    },
  },
  {
    "mason.nvim",
    opts = {
      ensure_installed = {
        "css-lsp",
        "html-lsp",
        "prettier",
      },
    },
  },
}
