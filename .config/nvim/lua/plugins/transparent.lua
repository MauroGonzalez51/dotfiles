return {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local transparent = require("transparent")

        transparent.setup({
            enable = true,
            extra_groups = {
                "NormalFloat",
                "NvimTreeNormal",
                "FloatBorder",
            },
            exclude = {},
        })

        transparent.clear_prefix("lualine")
        transparent.clear_prefix("snacks")
        transparent.clear_prefix("BufferLine")
        transparent.clear_prefix('WhichKey')

        local function clear_bg(name)
            local hl = vim.api.nvim_get_hl(0, { name = name })
            hl.bg = nil
            vim.api.nvim_set_hl(0, name, hl)
        end

        for _, group in ipairs({
            "DiagnosticVirtualTextError",
            "DiagnosticVirtualTextWarn",
            "DiagnosticVirtualTextInfo",
            "DiagnosticVirtualTextHint",

            "TabLine",
            "TabLineFill",
            "TabLineSel",

            "Pmenu",
            "PmenuSel",
            "PmenuMatch",
            "PmenuMatchSel",
        }) do
            clear_bg(group)
        end
    end,
}
