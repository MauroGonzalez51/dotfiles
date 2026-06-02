hl.bind(var_mod .. " + Return", hl.dsp.exec_cmd(var_terminal))
hl.bind(var_mod .. " + alt + X", hl.dsp.exec_cmd(var_power_menu))
hl.bind(var_mod .. " + shift + S", hl.dsp.exec_cmd(var_screenshot))
hl.bind("print", hl.dsp.exec_cmd(var_screenshot))
hl.bind(var_mod .. " + alt + comma", hl.dsp.exec_cmd("~/.local/bin/kb-layout --next"))

-- bind = $mod, R, hyprexpo:expo, toggle
hl.bind(var_mod .. " + alt + Backspace", hl.dsp.exec_cmd("~/.local/bin/hyprland-cheatsheet"))
hl.bind(var_mod .. " + M", hl.dsp.layout("swapwithmaster master"))
hl.bind(var_mod .. " + B", hl.dsp.exec_cmd(var_browser))
hl.bind(var_mod .. " + alt + B", hl.dsp.exec_cmd(var_bluetooth_manager))
hl.bind(var_mod .. " + shift + B", hl.dsp.exec_cmd("~/.local/bin/waybar-theme --select-wofi"))
hl.bind(var_mod .. " + Q", hl.dsp.window.close())
hl.bind(var_mod .. " + alt + R", hl.dsp.exec_cmd("kitty -e sh -c 'hyprctl reload; read'"))
hl.bind(var_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(var_mod .. " + SPACE", hl.dsp.exec_cmd(var_menu))
hl.bind(var_mod .. " + A", hl.dsp.focus({ workspace = -1 }), {
    repeating = true,
})
hl.bind(var_mod .. " + S", hl.dsp.focus({ workspace = "+1" }), {
    repeating = true,
})
hl.bind(var_mod .. " + D", hl.dsp.window.move({ workspace = -1 }), {
    repeating = true,
})
hl.bind(var_mod .. " + F", hl.dsp.window.move({ workspace = "+1" }), {
    repeating = true,
})
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
hl.bind(var_mod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(var_mod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mod .. " + alt + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(var_mod .. " + alt + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(var_mod .. " + alt + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(var_mod .. " + alt + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(var_mod .. " + shift + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), {
    repeating = true,
})
hl.bind(var_mod .. " + shift + J", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), {
    repeating = true,
})
hl.bind(var_mod .. " + shift + K", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), {
    repeating = true,
})
hl.bind(var_mod .. " + shift + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), {
    repeating = true,
})
hl.bind(var_mod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true,
})
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), {
    repeating = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), {
    repeating = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), {
    repeating = true,
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), {
    repeating = true,
})
hl.bind("switch:on:Lid Switch", hl.dsp.dpms("off"), {
    locked = true,
})
hl.bind("switch:off:Lid Switch", hl.dsp.dpms("on"), {
    locked = true,
})
