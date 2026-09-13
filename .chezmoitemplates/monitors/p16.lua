hl.monitor({
    output   = "desc:Eizo Nanao Corporation MX317W 0x015274D2",
    mode     = "4096x2160@59.98",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 409NTQD0X956",
    mode     = "2560x1440@143.99100",
    position = "4096x0",
    scale    = "1",
})

hl.monitor({
    output   = "desc:AU Optronics B160UAN06.N  0x00002BB4",
    mode     = "1920x1200@60.09600",
    position = "4196x1440",
    scale    = "1",
})

hl.workspace_rule({
  workspace   = "1",
  monitor     = "desc:AU Optronics B160UAN06.N  0x00002BB4",
  default     = true,
  persistent  = true,
})

hl.workspace_rule({
  workspace   = "2",
  monitor     = "desc:LG Electronics LG ULTRAGEAR 409NTQD0X956",
  default     = true,
  persistent  = true,
})

hl.workspace_rule({
  workspace   = "3",
  monitor     = "desc:Eizo Nanao Corporation MX317W 0x015274D2",
  default     = true,
  persistent  = true,
})

