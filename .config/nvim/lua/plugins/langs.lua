-- Extra treesitter parsers; LSP extras live in lazyvim.json.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "go",
        "gomod",
        "gosum",
        "gowork",
        "python",
        "c",
        "cpp",
        "rust",
        "toml",
        "javascript",
        "typescript",
        "tsx",
        "jsdoc",
        "css",
        "scss",
        "html",
        "json",
        "jsonc",
      })
    end,
  },
}
