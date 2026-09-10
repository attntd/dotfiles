local M = {}

local function number_or_zero(value)
    return tonumber(value) or 0
end

local function toggle_floating_fitted()
    local window = hl.get_active_window()
    local monitor = hl.get_active_monitor()

    if window == nil or monitor == nil then
        return
    end

    local was_tiled = not window.floating
    hl.dispatch(hl.dsp.window.float({ window = window, action = "toggle" }))

    if not was_tiled then
        return
    end

    local gaps = hl.get_config("general.gaps_out") or {}
    local reserved = monitor.reserved or {}
    local border = number_or_zero(hl.get_config("general.border_size"))
    -- Monitor dimensions are physical pixels; window geometry uses logical pixels.
    local scale = tonumber(monitor.scale) or 1

    local left = number_or_zero(reserved.left) + number_or_zero(gaps.left) + border
    local top = number_or_zero(reserved.top) + number_or_zero(gaps.top) + border
    local available_width = number_or_zero(monitor.width) / scale
        - number_or_zero(reserved.left)
        - number_or_zero(reserved.right)
        - number_or_zero(gaps.left)
        - number_or_zero(gaps.right)
        - 2 * border
    local available_height = number_or_zero(monitor.height) / scale
        - number_or_zero(reserved.top)
        - number_or_zero(reserved.bottom)
        - number_or_zero(gaps.top)
        - number_or_zero(gaps.bottom)
        - 2 * border

    local width = math.max(1, math.floor(available_width * 0.95))
    local height = math.max(1, math.floor(available_height * 0.95))

    hl.dispatch(hl.dsp.window.resize({
        window = window,
        x = width,
        y = height,
        relative = false,
    }))
    hl.dispatch(hl.dsp.window.move({
        window = window,
        x = math.floor(number_or_zero(monitor.x) + left + (available_width - width) / 2),
        y = math.floor(number_or_zero(monitor.y) + top + (available_height - height) / 2),
        relative = false,
    }))
end

function M.setup(bindings)
    local bind = bindings.bind
    local main_mod = "SUPER"
    local lock_command = os.getenv("HOME") .. "/.config/quickshell/scripts/lock-screen"

    for _, side in ipairs({ "left", "right" }) do
        local key = side == "left" and "Super_L" or "Super_R"
        bind(key, hl.dsp.global("quickshell-de:workspace-switcher-" .. side), {
            non_consuming = true,
            ignore_mods = true,
            transparent = true,
            description = "[Workspace] Track Super release",
        }, "workspace switcher " .. side)
    end
    bind(main_mod .. " + TAB", hl.dsp.global("quickshell-de:workspace-switcher-next"), {
        transparent = true,
        description = "[Workspace] Open switcher or cycle",
    }, "cycle workspace switcher")

    local close_window_bind = bind(
        main_mod .. " + C",
        hl.dsp.window.close(),
        { description = "[Window] Close" },
        "close window"
    )
    -- close_window_bind:set_enabled(false)

    bind(main_mod .. " + ALT + Q", hl.dsp.exit(), { description = "[Session] Exit Hyprland" }, "exit Hyprland")
    bind(main_mod .. " + F", toggle_floating_fitted, { description = "[Window] Toggle fitted floating" }, "toggle fitted floating")
    bind(main_mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "fullscreen" }), { description = "[Window] Toggle fullscreen" }, "toggle fullscreen")
    bind(main_mod .. " + P", hl.dsp.window.pseudo(), { description = "[Window] Toggle pseudo-tiling" }, "toggle pseudo-tiling")
    bind(main_mod .. " + S", hl.dsp.layout("togglesplit"), { description = "[Layout] Toggle split" }, "toggle split")

    bind(main_mod .. " + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"), { description = "[Notifications] Toggle center" }, "toggle notification center")
    bind(main_mod .. " + SHIFT + N", hl.dsp.exec_cmd("qs ipc call notifications toggleDnd"), { description = "[Notifications] Toggle do not disturb" }, "toggle do not disturb")

    bind(main_mod .. " + SHIFT + L", hl.dsp.exec_cmd(lock_command), { description = "[Session] Lock screen" }, "lock screen")

    bind(main_mod .. " + h", hl.dsp.focus({ direction = "left" }), { description = "[Focus] Left" }, "focus left")
    bind(main_mod .. " + l", hl.dsp.focus({ direction = "right" }), { description = "[Focus] Right" }, "focus right")
    bind(main_mod .. " + k", hl.dsp.focus({ direction = "up" }), { description = "[Focus] Up" }, "focus up")
    bind(main_mod .. " + j", hl.dsp.focus({ direction = "down" }), { description = "[Focus] Down" }, "focus down")

    for workspace = 1, 10 do
        local key = workspace % 10
        bind(
            main_mod .. " + " .. key,
            hl.dsp.focus({ workspace = workspace }),
            { description = "[Workspace] Focus " .. workspace },
            "focus workspace " .. workspace
        )
        bind(
            main_mod .. " + SHIFT + " .. key,
            hl.dsp.window.move({ workspace = workspace }),
            { description = "[Workspace] Move window to " .. workspace },
            "move window to workspace " .. workspace
        )
    end

    bind(main_mod .. " + M", hl.dsp.workspace.toggle_special("magic"), { description = "[Workspace] Toggle magic" }, "toggle magic workspace")
    bind(main_mod .. " + SHIFT + M", hl.dsp.window.move({ workspace = "special:magic" }), { description = "[Workspace] Move window to magic" }, "move window to magic workspace")

    bind("SHIFT + ALT + M", function()
        local active_window = hl.get_active_window()
        local regular_workspace = hl.get_active_workspace()

        if active_window == nil or active_window.workspace == nil or regular_workspace == nil then
            return
        end
        if active_window.workspace.name ~= "special:magic" then
            return
        end

        hl.dispatch(hl.dsp.window.move({
            window = active_window,
            workspace = regular_workspace,
            follow = true,
        }))
    end, { description = "[Workspace] Return window from magic" }, "return window from magic workspace")

    bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "[Workspace] Next" }, "next workspace")
    bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "[Workspace] Previous" }, "previous workspace")

    bind(main_mod .. " + mouse:272", hl.dsp.window.resize(), { mouse = true, description = "[Mouse] Resize window" }, "resize window with left button")
    bind(main_mod .. " + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "[Mouse] Move window" }, "drag window")
    bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "[Mouse] Resize window" }, "resize window")

    bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "[Hardware] Volume up" }, "volume up")
    bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true, description = "[Hardware] Volume down" }, "volume down")
    bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true, description = "[Hardware] Toggle audio mute" }, "toggle audio mute")
    bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true, description = "[Hardware] Toggle microphone mute" }, "toggle microphone mute")
    bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call brightness adjust 5 || brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true, description = "[Hardware] Brightness up" }, "brightness up")
    bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call brightness adjust -5 || brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true, description = "[Hardware] Brightness down" }, "brightness down")

    bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "[Media] Next" }, "next media")
    bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "[Media] Play or pause" }, "pause media")
    bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "[Media] Play or pause" }, "play media")
    bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "[Media] Previous" }, "previous media")

    return {
        close_window = close_window_bind,
    }
end

return M
