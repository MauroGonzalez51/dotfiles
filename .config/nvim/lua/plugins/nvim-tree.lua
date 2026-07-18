return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { sort = { sorter = "case_sensitive" }, renderer = { group_empty = true } },
    keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer" },
        { "<leader>o", "<cmd>NvimTreeFocus<CR>",  desc = "Focus Explorer" },
        { "<leader>p", "<C-w>p",                  desc = "Previous Window" },
    },
}
