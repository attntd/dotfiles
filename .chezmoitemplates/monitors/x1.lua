hl.monitor({
    output   = "desc:Eizo Nanao Corporation MX317W 0x015274D2",
    mode     = "4096x2160@59.98",
    position = "0x0",
    scale    = "1",
})

hl.monitor({
    output   = "desc:LG Electronics LG ULTRAGEAR 409NTQD0X956",
    mode     = "2560x1440@143.99",
    position = "4096x0",
    scale    = "1",
})

hl.monitor({
    output   = "desc:Samsung Display Corp. ATNA40HQ09-0  0x0000003B",
    mode     = "2880x1800@120.00Hz",
    position = "4196x1440",
    scale    = "1.5",
})

hl.workspace_rule({
  workspace   = "1",
  monitor     = "desc:Samsung Display Corp. ATNA40HQ09-0  0x0000003B",
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

