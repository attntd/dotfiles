hl.on("hyprland.start", function()
  hl.exec_cmd("uwsm app -- qs -n -d")
end)

--hl.on("hyprland.start", function ()
--  hl.exec_cmd("uwsm app -- waybar")
--  hl.exec_cmd("uwsm app -- hypridle")
--  hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
--end)
