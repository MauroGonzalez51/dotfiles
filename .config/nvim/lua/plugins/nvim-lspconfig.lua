return {
	"neovim/nvim-lspconfig",
	opts = {
		servers = {
			volar = {
				init_options = {
					vue = {
						hybrid_mode = true,
					},
				},
			},
			vtsls = {},
		},
	},
}
