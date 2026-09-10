-- Application keybinds
--
-- Shorthand: the table key is the command and the value is the shortcut.
-- Example: ["kitty"] = "SUPER + T",
--
-- Use the extended form when a command has arguments, needs a friendly name,
-- a description, options, or should be temporarily disabled.

return {
    ["kitty"] = "SUPER + RETURN",
    ["zen-browser"] = "SUPER + B",

    file_manager = {
        command = "kitty -e fish -lc yazi",
        bind = "SUPER + E",
        description = "[Apps] Yazi file manager",
    },

    app_launcher = {
        command = "qs ipc call launcher toggle",
        bind = "SUPER + SPACE",
        description = "[Apps] QuickShell launcher",
    },

    screenshot = {
        global = "quickshell-de:screenshot-open",
        bind = "PRINT",
        description = "[Screenshot] Open QuickShell capture",
    },

    screenshot_region = {
        global = "quickshell-de:screenshot-region",
        bind = "SHIFT + PRINT",
        description = "[Screenshot] Select region",
    },

    screenshot_window = {
        global = "quickshell-de:screenshot-window",
        bind = "SUPER + PRINT",
        description = "[Screenshot] Select visible window",
    },

    screenshot_monitor = {
        global = "quickshell-de:screenshot-monitor",
        bind = "CTRL + PRINT",
        description = "[Screenshot] Select monitor",
    },

    screenshot_firmware = {
        global = "quickshell-de:screenshot-region",
        -- The multimedia F11 key is emitted by this ASUS firmware as Super+Shift+S.
        bind = "SUPER + SHIFT + S",
        description = "[Screenshot] Select region (ASUS F11)",
    },

    dictation_toggle = {
        command = "voxtype record toggle",
        -- Copilot sends Super + Shift + keycode 201 (XF86Assistant).
        bind = "SUPER + SHIFT + code:201",
        description = "[Apps] Voxtype dictation toggle",
    },
}
