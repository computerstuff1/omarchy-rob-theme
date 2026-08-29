# Upstream feature requests

These are the two custom features that currently require de-forking Omarchy
built-ins. If accepted upstream, the `patches/` directory disappears and the
theme becomes 100% fork-free.

File each against the Omarchy repo with the diff and rationale below.

## 1. Floating bar (`bar.margin` / `bar.radius`)

**What it does:** lets the bar float inset from the screen edge with rounded
corners, driven entirely by `shell.json`:

```json
"bar": { "margin": 8, "radius": 14 }
```

**Diff:** `patches/bar.patch` (the floating-bar hunks of `Bar.qml`):

- add `barMargin` / `barRadius` properties
- read `config.margin` / `config.radius` in the config-apply block
- use `barMargin` in the window `margins`
- draw the bar background on a rounded, gradient-bordered surface

**Rationale:** this is a popular, generally-useful bar behavior (now common in
Waybar/Sway titles). Implementing it config-first means no one needs to fork
the bar engine. The theme's gradient border is already theme-driven via
`theme/shell.bar.toml` (`[bar] border`); only the inset/radius needs core support.

## 2. Clock second-hand precision (`precision` opt-in)

**What it does:** the built-in clock only ticks per minute, so a `format` of
`hh:mm:ss` shows a frozen `:ss`. This adds a seconds opt-in.

**Diff:** `patches/clock.patch` (one line in `panels/clock/BarWidget.qml`):

```diff
-    precision: SystemClock.Minutes
+    precision: /ss|s\b/.test(root.activeFormat) ? SystemClock.Seconds : SystemClock.Minutes
```

**Rationale:** auto-enabling `Seconds` precision when the active format
contains a second specifier is a small, safe win — otherwise a `:ss` format is
silently misleading. Alternatively, accept an explicit `"precision": "seconds"`
in `shell.json`; the color-example ends up equivalent.

---

Until these land, the theme ships `patches/` and re-applies them against the
current built-in at install time (and after each `omarchy update` via the
`post-update.d` hook), so it stays visually identical while tracking upstream.
