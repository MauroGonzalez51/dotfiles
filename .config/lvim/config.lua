-- Configuración de formateo
lvim.format_on_save.enabled = true
lvim.format_on_save.pattern = {
    "*.js", "*.jsx", "*.ts", "*.tsx", "*.json", "*.css", "*.html"
}

-- Configurar null-ls para ESLint y Prettier
local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup({
    {
        command = "prettier",
        filetypes = {
            "javascript", "javascriptreact", "typescript", "typescriptreact",
            "json", "css", "scss", "html"
        }
    }
})

local linters = require "lvim.lsp.null-ls.linters"
linters.setup({
    {
        command = "eslint",
        filetypes = {
            "javascript", "javascriptreact", "typescript", "typescriptreact"
        }
    }
})

-- Configurar code actions de ESLint
local code_actions = require "lvim.lsp.null-ls.code_actions"
code_actions.setup({
    {
        command = "eslint",
        filetypes = {
            "javascript", "javascriptreact", "typescript", "typescriptreact"
        }
    }
})

lvim.transparent_window = true

lvim.builtin.lualine.options.theme = "auto"
local lualine = require('lualine.themes.auto')

for _, section in pairs(lualine) do
    section.a.bg = "none"
    section.b.bg = "none"
    section.c.bg = "none"
end

lvim.builtin.lualine.options.theme = lualine
