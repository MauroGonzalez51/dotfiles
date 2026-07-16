return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 500,
    config = function()
        require('catppuccin').setup({
            flavour = "macchiato",
            transparent_background = vim.g.transparent_enabled,
            float = { transparent = vim.g.transparent_enabled, solid = false }
        })

        vim.cmd.colorscheme("catppuccin")
    end
}
