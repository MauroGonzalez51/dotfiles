hl.config({
	general = {
		border_size = 3,
		gaps_in = 3,
		gaps_out = 10,
		col = {
			active_border = { colors = { Color12, Color13 }, angle = 45 },
			inactive_border = Color1,
		},
		snap = {
			enabled = true,
		},
	},
	decoration = {
		rounding = 10,
		inactive_opacity = 0.85,
		blur = {
			enabled = true,
			size = 10,
			passes = 1,
			new_optimizations = true,
		},
		glow = {
			enabled = true,
			color = { colors = { Color12, Color13 }, angle = 45 },
			color_inactive = Color1,
		},
	},
	animations = {
		workspace_wraparound = true,
	},
})
