-- Monitor configuration
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
--
-- Default: auto-configure every connected monitor at its preferred mode,
-- auto-placed, scale 1. Replace with explicit entries as needed, e.g.:
--   hl.monitor({ output = "DP-1",  mode = "2560x1440@144", position = "0x0",  scale = 1 })
--   hl.monitor({ output = "eDP-1", mode = "preferred",     position = "auto", scale = 1.5 })

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})
