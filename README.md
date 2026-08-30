# omarchy-rob-theme

TRY IN VM, One-command install of my **Omarchy** desktop — a dark "Rob Theme" (Tokyo Night
palette) with a blue `#1793d1` accent and a matching shell, bar, and window-border
gradient.

<img width="1920" height="1080" alt="screenshot-2026-08-28_07-21-06" src="https://github.com/user-attachments/assets/3d85bb3e-3f1f-48e3-a0f0-2f661d286b5c" />

<img width="1920" height="1080" alt="screenshot-2026-08-28_10-40-57" src="https://github.com/user-attachments/assets/f1857554-05b5-4f94-967e-8ef39d00ceb6" />


## Install

```bash
git clone https://github.com/computerstuff1/omarchy-rob-theme
cd omarchy-rob-theme
./install.sh
```

That's it. The script:

1. Installs dependencies (`pacman-contrib`, `jq`, `ttf-jetbrains-mono-nerd-basic`, `yaru-icon-theme`, `yay` — best-effort)
2. Stages the theme into `~/.config/omarchy/themes/rob-theme/`
3. Applies it with `omarchy theme set "Rob Theme"`
4. Installs the bar layout, plugins, Hyprland look, starship, ghostty, fastfetch, vim, and the update-count helper
5. Registers the bar widgets, installs a `post-update` hook, and reloads the shell + Hyprland

**Options:**

| Flag | Effect |
|---|---|
| `--yes` | Non-interactive; skip confirmations |
| `--no-deps` | Skip the package-install step entirely |
| `--aur-helper=yay\|paru\|none` | Choose the AUR helper (default `yay`; `none` skips it) |
| `--uninstall` | Restore the most recent backup and remove the theme's changes |
| `--restore=<ts>` | Restore a specific timestamped backup from `~/.cache/omarchy-rob-theme/backup/<ts>` |

Dependencies are installed only if missing: `pacman-contrib` (for `checkupdates`),
`jq` (for the de-forked clones), `ttf-jetbrains-mono-nerd-basic` (the monospace
font), `yaru-icon-theme` (icons), and your chosen AUR helper (`yay` or `paru`)
for the AUR update count.

**Re-runnable:** safe to run any time. The first run saves timestamped backups of
anything it overwrites under `~/.cache/omarchy-rob-theme/backup/<timestamp>/`;
later runs just refresh to this repo's state, only backing up files that actually
changed, and keep the newest 5 backups. It never deletes personal settings.

**Undo:** run `./install.sh --uninstall` to restore the most recent backup and
remove the theme's changes (hooks, clones, widget registrations), or
`./install.sh --restore=<timestamp>` to go back to an earlier state.

## What's inside

```
omarchy-rob-theme/
├── install.sh                  one command, full setup
├── backgrounds/default.png      bundled wallpaper
├── patches/                     minimal diffs re-applied to current built-ins
│   ├── bar.patch                floating bar (margin/radius + gradient surface)
│   └── clock.patch              seconds-ticking clock precision
├── docs/upstream.md             the two upstream feature requests
├── theme/                       the "Rob Theme"
│   ├── colors.toml              Tokyo Night palette + accent/border gradient
│   ├── shell.bar.toml           bar surface (background/text/size/border)
│   ├── shell.lock.toml          lock screen surface
│   ├── shell.menu.toml          menu surface
│   └── icons.theme              Yaru-red
└── dotfiles/
    ├── shell.json               bar layout (left/center/right)
    ├── starship/starship.toml   two-line prompt
    ├── hypr/                    looknfeel (borders/gaps/master/blur), bindings, base flags
    ├── fontconfig/fonts.conf    JetBrainsMono Nerd Font
    ├── ghostty/config           terminal font/size/padding/keybinds
    ├── kitty/kitty.conf         terminal font/padding/opacity/tab style
    ├── kitty/current-theme.conf Catppuccin-Mocha palette (overrides the theme)
    ├── fastfetch/               config + custom Linux logo (path auto-rewritten)
    ├── plugins/rob.{menubutton,workspaces,updates}   self-contained bar widgets
    ├── hooks/rob-theme-repatch.sh                    post-update hook
    ├── vim/                     .vimrc + catppuccin_mocha.vim colorscheme
    └── bin/system-update-count  pending repo+AUR update counter
```

## The look

| Element | Value |
|---|---|
| Accent | `#1793d1` |
| Border gradient | `#1793d1 → #999999 @ 90°` (bar, popups, notifications, windows) |
| Palette | Tokyo Night (`background #1a1b26`, `foreground #a9b1d6`) |
| Window border | 4px, rounded 8, master layout (`mfact 0.55`, left) |
| Blur | enabled (size 3, passes 2) |
| Gaps | in 5 / out 10 |
| Font | JetBrainsMono Nerd Font |
| Icons | Yaru-red |
| Wallpaper | `default.png` |

## Customizing

Everything you might want to tweak is a plain file in this repo. Edit it, then
re-apply (the `Re-apply` column below). `install.sh` is safe to re-run any time,
but individual changes apply faster with the commands listed.

### Where the files live

| What you're editing | Repo source | Installed to |
|---|---|---|
| Theme colors | `theme/colors.toml` | `~/.config/omarchy/themes/rob-theme/colors.toml` |
| Bar surface | `theme/shell.bar.toml` | `~/.config/omarchy/themes/rob-theme/shell.bar.toml` |
| Lock screen surface | `theme/shell.lock.toml` | `~/.config/omarchy/themes/rob-theme/shell.lock.toml` |
| Menu surface | `theme/shell.menu.toml` | `~/.config/omarchy/themes/rob-theme/shell.menu.toml` |
| Icon theme | `theme/icons.theme` | `~/.config/omarchy/themes/rob-theme/icons.theme` |
| Wallpaper | `backgrounds/default.png` | `~/.config/omarchy/themes/rob-theme/backgrounds/default.png` |
| Bar layout / widget placement | `dotfiles/shell.json` | `~/.config/omarchy/shell.json` |
| Shell prompt | `dotfiles/starship/starship.toml` | `~/.config/starship.toml` |
| Window look (gaps/borders/blur/master) | `dotfiles/hypr/looknfeel.lua` | `~/.config/hypr/looknfeel.lua` |
| Key bindings | `dotfiles/hypr/bindings.lua` | `~/.config/hypr/bindings.lua` |
| Hyprland load order / flags | `dotfiles/hypr/hyprland.lua` | `~/.config/hypr/hyprland.lua` |
| Terminal font/padding/keybinds (ghostty) | `dotfiles/ghostty/config` | `~/.config/ghostty/config` |
| Terminal font/padding/opacity (kitty) | `dotfiles/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| Kitty palette (Catppuccin) | `dotfiles/kitty/current-theme.conf` | `~/.config/kitty/current-theme.conf` |
| Monospace font | `dotfiles/fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` |
| fastfetch | `dotfiles/fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |
| fastfetch logo | `dotfiles/fastfetch/Linux.png` | `~/.local/share/omarchy-rob-theme/Linux.png` |
| Vim | `dotfiles/vim/vimrc`, `dotfiles/vim/colors/` | `~/.vimrc`, `~/.vim/colors/` |
| Update-count script | `dotfiles/bin/system-update-count` | `~/.config/omarchy/bin/system-update-count` |
| Logo button / workspace / updates widgets | `dotfiles/plugins/rob.{menubutton,workspaces,updates}/` | `~/.config/omarchy/plugins/` |
| Floating bar + seconds clock | `patches/{bar,clock}.patch` | generated → `~/.config/omarchy/plugins/rob.{bar,clock}/` |

### Colors, accent & palette

The palette is **Tokyo Night**, accent **`#1793d1`**, and lives in
`theme/colors.toml`. Change `accent` or any named color there, and everything
that reads Omarchy's theme colors (bar, terminals, prompt via `colors.toml`)
follows. The window/bar **border gradient** is also defined here (`accent` +
`hyprland_active_border`), so it drives Hyprland window borders and the shell
surfaces together. The **menu** styling is a per-section override in
`theme/shell.menu.toml`.

> Note: **ghostty** colors come from the theme dynamically — its config
> `include`s Omarchy's generated theme file (`~/.local/state/omarchy/current/theme/ghostty.conf`).
> To recolor ghostty, edit `theme/colors.toml`. **kitty**, meanwhile, uses a
> bundled **Catppuccin Mocha** palette (`dotfiles/kitty/current-theme.conf`) that
> overrides the theme, so recolouring kitty means editing that file instead.

**Re-apply:** `omarchy theme set "Rob Theme"`.

### Bar layout & widgets

Reorder, add, or remove bar widgets in `dotfiles/shell.json` (`bar.layout`).
Built-in widgets use `omarchy.*` ids; the theme's custom ones are
`rob.menubutton` (logo), `rob.workspaces` (workspace rings), and `rob.updates`
(update count). The bar's `id` must stay `rob.bar` (the patched floating bar).

- Change the clock format on the `omarchy.clock` entry's `format` field
  (the `rob.clock` clone ticks seconds whenever `ss`/`s` is present).
- `rob.updates` shows repo+AUR counts from `dotfiles/bin/system-update-count`
  (needs `checkupdates` and `yay` or `paru`). Tweak the poll interval in
  `dotfiles/plugins/rob.updates/SystemUpdates.qml`.

**Re-apply:** `shell.json` hot-reloads on save; widget code under
`~/.config/omarchy/plugins/` reloads on save. Force with `omarchy restart shell`.

### Floating bar & seconds clock (the patches)

These are implemented as minimal patches against the current built-ins —
see [`docs/upstream.md`](docs/upstream.md) for the full diff and rationale.

- **Floating bar** inset/rounding: add `"margin": 8` / `"radius": 14` to the
  `bar` object in `dotfiles/shell.json` (the patched `rob.bar` reads these).
- **Gradient surface / indicator thickness** ship inside `patches/bar.patch`; the
  surface follows `Color.accent`, so recolor it in `theme/colors.toml`.

**Re-apply:** `./install.sh` (re-clones + re-patches), or the same thing runs
automatically after each `omarchy update` via the `post-update` hook.

### Hyprland look & feel

- Gaps, borders, rounded corners, blur, master layout: `dotfiles/hypr/looknfeel.lua`.
- Key bindings (bind/unbind): `dotfiles/hypr/bindings.lua`.
- Load order / flags / which `hypr.*` files load first: `dotfiles/hypr/hyprland.lua`.

**Re-apply:** Hyprland auto-reloads on save; verify with `hyprctl reload` and
`hyprctl configerrors`.

### Terminals, prompt, font, vim, fastfetch

- **Ghostty:** `dotfiles/ghostty/config` (font, size, padding, keybinds).
- **Kitty:** `dotfiles/kitty/kitty.conf` (font, padding, opacity, tab style) and
  `dotfiles/kitty/current-theme.conf` (Catppuccin Mocha palette).
- **Prompt:** `dotfiles/starship/starship.toml` (two-line layout, module colors).
- **Font:** the theme uses `JetBrainsMono Nerd Font`. Change it in
  `dotfiles/fontconfig/fonts.conf` (system monospace) *and* the ghostty/kitty
  configs (or run `omarchy font set <name>` instead; `omarchy font list`).
- **Vim:** `dotfiles/vim/vimrc` (statusline, indentation, colorscheme call) and
  `dotfiles/vim/colors/catppuccin_mocha.vim`.
- **fastfetch:** `dotfiles/fastfetch/config.jsonc` — note the logo `source` is
  the placeholder `@LOGO_PATH@` that `install.sh` rewrites at install time, so
  keep it as-is when editing.

**Re-apply:** terminals → `omarchy restart terminal`; starship/vim/fastfetch →
  new shell / next launch. `./install.sh` re-stages any of these.

### Wallpaper & icons

- **Wallpaper:** replace `backgrounds/default.png` (any resolution; keep the name).
- **Icons:** set the GTK icon theme name in `theme/icons.theme` (currently `Yaru-red`).
  The file holds a single name — no comments — because Omarchy reads the whole
  file as the icon-theme name. The available Yaru folder colours are:

  ```
  Yaru-red          ← current
  # Yaru            (default orange)
  # Yaru-blue
  # Yaru-magenta
  # Yaru-olive
  # Yaru-prussiangreen
  # Yaru-purple
  # Yaru-sage
  # Yaru-wartybrown
  # Yaru-yellow
  ```

  To change it, replace `theme/icons.theme` with the single colour you want and
  re-apply Theme.

**Re-apply:** `omarchy theme set "Rob Theme"` (then `omarchy theme bg next` to
cycle wallpapers).

### Quick start: the 3 most common edits

```bash
# 1. Change the accent colour everywhere
sed -i 's/#1793d1/#YOURHEX/' theme/colors.toml && omarchy theme set "Rob Theme"

# 2. Make the bar float more / less
#    edit dotfiles/shell.json -> "bar": { "margin": 12, "radius": 16 }
omarchy restart shell

# 3. Close the window gaps in tighter
#    edit dotfiles/hypr/looknfeel.lua -> gaps_in / gaps_out, then:
hyprctl reload
```

## Update-proof design

The theme is built to survive `omarchy update` and track upstream improvements:

- **Everything lives in `~/.config/`** (theme, `shell.json`, `hypr/`,
  terminals, starship, fastfetch, vim) — Omarchy never overwrites user
  config, so these never break on update.
- **No vendored built-in forks.** Instead of shipping stale copies of the bar
  engine and clock, `install.sh` clones the *current* built-in
  (`omarchy.bar`, `omarchy.clock`) into a fixed `rob.*` id and re-applies a
  minimal `patches/*.patch` on top. It keeps `clonedFrom` so the shell routes
  IPC correctly, and it inherits any fixes that land in the built-in.
- **A `post-update` hook** re-applies those patches after every `omarchy update`,
  so the floating bar and seconds clock keep working and pick up upstream
  changes. If a patch ever stops applying, the last-good clone is left in place
  with a warning (never a broken bar).
- **Custom widgets** (`rob.menubutton`, `rob.workspaces`, `rob.updates`) are
  self-contained third-party `bar-widget`s — the supported extension model — not
  forks of internals.

The only two things the built-ins can't express yet are the **floating bar**
(`bar.margin`/`bar.radius`) and **seconds-ticking clock** (`precision`); both are
written up as upstream feature requests in [`docs/upstream.md`](docs/upstream.md).
When they land, `patches/` and the hook disappear entirely.

## Notes

- fastfetch's logo is bundled and its path is rewritten at install, so there are no
  machine-specific absolute paths in this repo.
- The update-count widget (`rob.updates`) reads `checkupdates` and `yay`/`paru`,
  so it needs `pacman-contrib` and an AUR helper; `omarchy.system-update` is the
  dependency-free alternative if you don't want the number.
- Non-look personal settings (git identity, monitors, input) are intentionally not
  included.
