return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 500,
    setup = function()
        local theme = require('catppuccin')

        theme.setup({
            flavour = "macchiato",
            transparent_background = vim.g.transparent_enabled,
            float = {transparent = vim.g.transparent_enabled, solid = false}
        })
    end
}
