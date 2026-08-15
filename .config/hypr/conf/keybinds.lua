--------------------
---- APPS ----------
--------------------
hl.bind(MOD .. " + Return", hl.dsp.exec_cmd(TERMINAL))
hl.bind(MOD .. " + B", hl.dsp.exec_cmd(BROWSER))
hl.bind(MOD .. " + SPACE", hl.dsp.exec_cmd(MENU))
hl.bind(MOD .. " + ALT + B", hl.dsp.exec_cmd(BLUETOOTH_MANAGER))
hl.bind(MOD .. " + ALT + X", hl.dsp.exec_cmd(POWER_MENU))
hl.bind(MOD .. " + SHIFT + S", hl.dsp.exec_cmd(SCREENSHOT))
hl.bind("print", hl.dsp.exec_cmd(SCREENSHOT))
hl.bind(MOD .. " + SHIFT + B", hl.dsp.exec_cmd("~/.local/bin/waybar-theme --select-wofi"))
hl.bind(MOD .. " + ALT + comma", hl.dsp.exec_cmd("~/.local/bin/kb-layout --next"))
hl.bind(MOD .. " + ALT + Backspace", hl.dsp.exec_cmd("~/.local/bin/hyprland-cheatsheet"))
hl.bind(MOD .. " + ALT + R", hl.dsp.exec_cmd("kitty -e sh -c 'hyprctl reload; read'"))

--------------------
---- WINDOWS -------
--------------------
hl.bind(MOD .. " + Q", hl.dsp.window.close())
hl.bind(MOD .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(MOD .. " + M", hl.dsp.layout("swapwithmaster master"))

--------------------
---- FOCUS ---------
--------------------
hl.bind(MOD .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(MOD .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(MOD .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(MOD .. " + L", hl.dsp.focus({ direction = "right" }))

--------------------
---- MOVE ----------
--------------------
hl.bind(MOD .. " + ALT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(MOD .. " + ALT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(MOD .. " + ALT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(MOD .. " + ALT + L", hl.dsp.window.move({ direction = "right" }))

--------------------
---- RESIZE --------
--------------------
hl.bind(MOD .. " + SHIFT + H", hl.dsp.window.resize({ delta = { -10, 0 } }), { repeating = true })
hl.bind(MOD .. " + SHIFT + J", hl.dsp.window.resize({ delta = { 0, -10 } }), { repeating = true })
hl.bind(MOD .. " + SHIFT + K", hl.dsp.window.resize({ delta = { 0, 10 } }), { repeating = true })
hl.bind(MOD .. " + SHIFT + L", hl.dsp.window.resize({ delta = { 10, 0 } }), { repeating = true })

--------------------
---- WORKSPACES ----
--------------------
hl.bind(MOD .. " + A", hl.dsp.focus({ workspace = "e-1" }), { repeating = true })
hl.bind(MOD .. " + S", hl.dsp.focus({ workspace = "e+1" }), { repeating = true })
hl.bind(MOD .. " + D", hl.dsp.window.move({ workspace = "e-1" }), { repeating = true })
hl.bind(MOD .. " + F", hl.dsp.window.move({ workspace = "e+1" }), { repeating = true })

--------------------
---- MOUSE ---------
--------------------
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

--------------------
---- GESTURES ------
--------------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

--------------------
---- MEDIA KEYS ----
--------------------
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("swayosd-client --playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("swayosd-client --playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("swayosd-client --playerctl prev"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { repeating = true })

--------------------
---- LID SWITCH ----
--------------------
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms off"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("hyprctl dispatch dpms on"), { locked = true })
