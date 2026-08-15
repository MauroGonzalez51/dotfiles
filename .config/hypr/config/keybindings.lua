local mainMod = "SUPER"

hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd(Terminal .. " -e sh -c 'hyprctl reload; read'"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(Terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(Browser))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(Menu))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + A", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + S", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + D", hl.dsp.window.move({ workspace = "-1" }))
hl.bind(mainMod .. " + F", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
