var_terminal = "kitty"
var_mod = "SUPER"
var_browser = "microsoft-edge-stable"
var_menu = "wofi --show drun --insensitive --allow-images --no-actions"
var_bluetooth_manager = "kitty -e bluetui"
var_power_menu = "~/.local/bin/power-menu"
var_screenshot = "~/.local/bin/hyprshot"

require("themes.wallust")
require("appearance")
require("keybinds")
require("input")
require("rules")
require("hyprland-gui")
require("plugins.hyprexpo")

hl.on("hyprland.start", function()
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("swaync")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("~/.local/bin/waybar-theme --init")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpm reload -n")
end)
