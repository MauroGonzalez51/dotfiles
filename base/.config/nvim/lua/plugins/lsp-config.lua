return {
    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                preset = "default",
                ["<Tab>"] = { "select_and_accept", "fallback" },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                eslint = {
                    filetypes = {
                        "javascript", "javascriptreact", "javascript.jsx",
                        "typescript", "typescriptreact", "typescript.tsx",
                        "vue", "html", "markdown", "json", "jsonc", "yaml",
                    },
                    settings = {
                        workingDirectories = { mode = "auto" },
                        rulesCustomizations = {
                            { rule = "style/*",   severity = "off", fixable = true },
                            { rule = "format/*",  severity = "off", fixable = true },
                            { rule = "*-indent",  severity = "off", fixable = true },
                            { rule = "*-spacing", severity = "off", fixable = true },
                            { rule = "*-spaces",  severity = "off", fixable = true },
                            { rule = "*-order",   severity = "off", fixable = true },
                            { rule = "*-dangle",  severity = "off", fixable = true },
                            { rule = "*-newline", severity = "off", fixable = true },
                            { rule = "*quotes",   severity = "off", fixable = true },
                            { rule = "*semi",     severity = "off", fixable = true },
                        },
                    },
                }
            },
        }
    }
}
