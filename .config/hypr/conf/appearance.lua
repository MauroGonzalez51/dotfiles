--------------------
---- GENERAL -------
--------------------
hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 3,
		col = {
			active_border = { colors = { COLOR3, COLOR6 }, angle = 45 },
			inactive_border = BACKGROUND,
		},
		layout = "dwindle",
	},
	decoration = {
		rounding = 8,
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
		},
	},
	animations = {
		enabled = true,
	},
	dwindle = {
		preserve_split = true,
		smart_split = true,
	},
	master = {
		new_status = "slave",
		orientation = "left",
		mfact = 0.55,
	},
	misc = {
		animate_manual_resizes = true,
		animate_mouse_windowdragging = true,
	},
})

hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

--------------------
---- MONITOR -------
--------------------
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

--------------------
---- WORKSPACES ----
--------------------
hl.workspace_rule({ workspace = "1", layout = "master" })
hl.workspace_rule({ workspace = "2", layout = "master" })
hl.workspace_rule({ workspace = "3", layout = "master" })
