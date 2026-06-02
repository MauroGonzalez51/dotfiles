hl.window_rule({
    name = "\"Picture In Picture\"",
    match = {
        title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$",
    },
    float = true,
    keep_aspect_ratio = true,
    pin = true,
    move = "(monitor_w*0.73) (monitor_h*0.72)",
    size = "(monitor_w*0.25) (monitor_h*0.25)",
})
hl.window_rule({
    name = "\"Picture In Picture (TWITCH)\"",
    match = {
        initial_class = "\"microsoft-edge\"",
        initial_title = "\"Untitled - Personal - Microsoft Edge\"",
        title = "\"Twitch - Personal - Microsoft Edge\"",
    },
    float = true,
    keep_aspect_ratio = true,
    pin = true,
    move = "(monitor_w*0.73) (monitor_h*0.72)",
    size = "(monitor_w*0.25) (monitor_h*0.25)",
})
hl.window_rule({
    name = "\"Microsoft Edge\"",
    match = {
        class = "^(microsoft-edge)$",
        title = "^()$",
    },
    no_initial_focus = true,
})
hl.window_rule({
    name = "xwayland-video-bridge-fixes",
    match = {
        class = "xwaylandvideobridge",
    },
    no_initial_focus = true,
    no_focus = true,
    no_anim = true,
    no_blur = true,
    max_size = "1 1",
    opacity = 0.0,
})
hl.layer_rule({
    name = "waybar",
    match = {
        namespace = "waybar",
    },
    no_anim = true,
})
