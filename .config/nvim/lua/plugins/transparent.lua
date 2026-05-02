return {
    "xiyaowong/transparent.nvim",
    lazy = false,
    priority = 1000,
    config = function()
        local transparent = require('transparent')

        transparent.setup({
            extra_groups = {"NormalFloat", "NvimTreeNormal", "TelescopeNormal"}
        })
    end
}
