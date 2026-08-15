--------------------
---- WINDOW RULES --
--------------------

-- Picture In Picture
hl.window_rule({
	name = "picture-in-picture",
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	float = true,
	keep_aspect_ratio = true,
	pin = true,
	move = { "monitor_w*0.73", "monitor_h*0.72" },
	size = { "monitor_w*0.25", "monitor_h*0.25" },
})

-- Picture In Picture (Twitch)
hl.window_rule({
	name = "picture-in-picture-twitch",
	match = {
		initial_class = "microsoft-edge",
		initial_title = "Untitled - Personal - Microsoft Edge",
		title = "Twitch - Personal - Microsoft Edge",
	},
	float = true,
	keep_aspect_ratio = true,
	pin = true,
	move = { "monitor_w*0.73", "monitor_h*0.72" },
	size = { "monitor_w*0.25", "monitor_h*0.25" },
})

-- Microsoft Edge empty title
hl.window_rule({
	name = "edge-no-focus",
	match = { class = "^(microsoft-edge)$", title = "^()$" },
	no_initial_focus = true,
})

-- xwayland-video-bridge fixes
hl.window_rule({
	name = "xwayland-video-bridge-fixes",
	match = { class = "xwaylandvideobridge" },
	no_initial_focus = true,
	no_focus = true,
	no_anim = true,
	no_blur = true,
	max_size = { 1, 1 },
	opacity = "0.0",
})

--------------------
---- LAYER RULES ---
--------------------

-- Waybar
hl.layer_rule({
	name = "waybar",
	match = { namespace = "waybar" },
	no_anim = true,
})
