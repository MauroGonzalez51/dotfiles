-- ╔══════════════════════════════════════════════╗
-- ║         Hyprland Configuration (Lua)        ║
-- ╚══════════════════════════════════════════════╝

--------------------
---- PROGRAMS ------
--------------------
TERMINAL = "kitty"
MOD = "SUPER"
BROWSER = "microsoft-edge-stable"
MENU = "wofi --show drun --insensitive --allow-images --no-actions"
BLUETOOTH_MANAGER = "kitty -e bluetui"
POWER_MENU = "~/.local/bin/power-menu"
SCREENSHOT = "~/.local/bin/hyprshot"

--------------------
---- MODULES -------
--------------------
require("conf/themes")
require("conf/appearance")
require("conf/input")
require("conf/keybinds")
require("conf/rules")

--------------------
---- AUTOSTART -----
--------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("swaync")
	hl.exec_cmd("waypaper --restore")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("~/.local/bin/waybar-theme --init")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("hyprpm reload -n")
	hl.exec_cmd("kdeconnectd")
end)
