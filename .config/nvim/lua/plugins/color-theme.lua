return {
    { "folke/tokyonight.nvim", enabled = false },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        lazy = false,
        opts = {
            flavour = "macchiato",
            transparent_background = vim.g.transparent_enabled,
            float = {
                transparent = vim.g.transparent_enabled,
                solid = false,
            },
        },
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        },
    },
    {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
            if (vim.g.colors_name or ""):find("catppuccin") then
                opts.highlights = require("catppuccin.special.bufferline").get_theme()
            end
        end,
    },
}
