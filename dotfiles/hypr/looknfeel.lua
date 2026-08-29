-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- No gaps between windows or borders.
    gaps_in = 5,
    gaps_out = 10,
    border_size = 4,
    layout = "master",
  },
})

hl.config({
  master = {
    mfact = 0.55,
    new_status = "slave",
    orientation = "left",
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 8,

    -- Dim unfocused windows
    dim_inactive = true,
    dim_strength = 0.15,

    -- Control transparency levels
    -- active_opacity = 0.85,
    -- inactive_opacity = 0.85,
    -- fullscreen_opacity = 1.0,   -- Keeps fullscreen apps completely solid

    -- Add background blur
    blur = {
      enabled = true,
      size = 3,
      passes = 2,
    },
  },
})



