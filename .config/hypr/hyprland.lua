Terminal = "kitty"
Browser = "microsoft-edge-stable"
Menu = "wofi --show drun --insensitive --allow-images --no-actions"

require("themes.colors")
require("config.keybindings")
require("config.input")
require("config.monitors")
require("config.appearance")

hl.on("hyprland.start", function()
	hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)
