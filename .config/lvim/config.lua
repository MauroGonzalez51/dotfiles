-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

-- Configuración de formateo
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.css", "*.html" }

-- Configurar null-ls para ESLint y Prettier
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup({
  {
    command = "prettier",
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "css", "scss", "html" },
  },
})

local linters = require "lvim.lsp.null-ls.linters"
linters.setup({
  {
    command = "eslint",
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
})

-- Configurar code actions de ESLint
local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup({
  {
    command = "eslint",
    filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  },
})
