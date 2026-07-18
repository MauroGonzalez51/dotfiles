return {
    {
        "mason-org/mason.nvim",
        opts = {}
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        dependencies = {
            "mason-org/mason.nvim",
        },
        config = function()
            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                callback = function(ev)
                    local map = vim.keymap.set
                    map("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Go to Declaration" })
                    map("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition" })
                    map("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover Documentation" })
                    map("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename Symbol" })
                    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Action" })
                    map("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Go to References" })
                end,
            })

            vim.lsp.config('vtsls', {
                filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
                settings = {
                    vtsls = {
                        tsserver = {
                            globalPlugins = {
                                {
                                    name = '@vue/typescript-plugin',
                                    location = vim.fn.stdpath('data') ..
                                    "/mason/packages/vue-language-server/node_modules/@vue/language-server",
                                    languages = { 'vue' },
                                    configNamespace = 'typescript',
                                }
                            },
                        },
                    },
                },
            })

            vim.lsp.enable('vue_ls')
            vim.lsp.enable('vtsls')
            vim.lsp.enable('pyright')
            vim.lsp.enable('lua_ls')
        end
    }
}
