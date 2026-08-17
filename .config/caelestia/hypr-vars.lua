return {
	browser = "microsoft-edge-stable",
	terminal = "kitty",
	fileExplorer = "nautilus --new-window",

	-- Workspace nav on A/S, move window on D/F (frees up F, so fullscreen moves to SHIFT+F)
	kbPrevWs = { "SUPER + A", "SUPER + mouse_up", "CTRL + SUPER + Left", "SUPER + Page_Up" },
	kbNextWs = { "SUPER + S", "SUPER + mouse_down", "CTRL + SUPER + Right", "SUPER + Page_Down" },
	kbMoveWinToWsPrev = { "SUPER + D", "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
	kbMoveWinToWsNext = { "SUPER + F", "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
	kbWindowFullscreen = "SUPER + SHIFT + F",

	-- Disable jump-to-workspace-N (SUPER + 0-9), replaced by A/S prev-next nav above
	kbGoToWs = "",

	-- Special workspace toggles now free to live on plain SUPER + 1..5
	kbSpecialWs = "SUPER + 1",
	kbCommunicationWs = "SUPER + 2",
	kbMusicWs = "SUPER + 3",
	kbSystemMonitorWs = "SUPER + 4",
	kbTodoWs = "SUPER + 5",

	-- Launcher off bare SUPER tap, onto SUPER + Space; terminal onto SUPER + Return
	kbLauncher = "SUPER + Space",
	kbTerminal = "SUPER + Return",
}
