---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "pl",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity    = 0,    -- -1.0 - 1.0, 0 means no modification.
        natural_scroll = true,

        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            tap_to_click = false,
            tap_button_map = "lrm",
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "tpps/2-elan-trackpoint",
    sensitivity = -0.35,
    scroll_method = "on_button_down",
    scroll_button = 274,
    scroll_button_lock = true,
})


