return {
	"atiladefreitas/lazyclip",
	config = function()
		require("lazyclip").setup({})
	end,
	keys = {
		{ "Cw", desc = "Open clipboard manager" },
	},
	event = { "TextYankPost" },
}
