# omarchy-rob-theme

One-command install of my **Omarchy** desktop — a dark "Rob Theme" (Tokyo Night
palette) with a blue `#1793d1` accent and a matching shell, bar, and window-border
gradient.

<img width="1920" height="1080" alt="screenshot-2026-08-28_07-21-06" src="https://github.com/user-attachments/assets/3d85bb3e-3f1f-48e3-a0f0-2f661d286b5c" />


## Install

```bash
git clone https://github.com/computerstuff1/omarchy-rob-theme
cd omarchy-rob-theme
./install.sh
```

That's it. The script:

1. Installs dependencies (`pacman-contrib`, `yaru-icon-theme`, `yay` — best-effort)
2. Stages the theme into `~/.config/omarchy/themes/rob-theme/`
3. Applies it with `omarchy theme set "Rob Theme"`
4. Installs the bar layout, plugins, Hyprland look, starship, ghostty, fastfetch, vim, and the update-count helper
5. Registers the bar widgets and reloads the shell + Hyprland

**Options:** `--yes` (non-interactive) and `--no-deps` (skip package installs).

**Re-runnable:** safe to run any time. The first run saves timestamped backups of
anything it overwrites under `~/.cache/omarchy-rob-theme/backup/<timestamp>/`;
later runs just refresh to this repo's state. It never deletes personal settings.

## What's inside

```
omarchy-rob-theme/
├── install.sh                  one command, full setup
├── backgrounds/default.png      bundled wallpaper
├── theme/                       the "Rob Theme"
│   ├── colors.toml              Tokyo Night palette
│   ├── shell.bar.toml           bar surface
│   ├── shell.lock.toml          lock screen surface
│   ├── icons.theme              Yaru-magenta
│   └── keyboard.rgb             ff00ff
└── dotfiles/
    ├── shell.json               bar layout (left/center/right)
    ├── shell.toml               [bar] + [hyprland] 90° border gradient
    ├── starship/starship.toml   two-line prompt
    ├── hypr/                    looknfeel (borders/gaps/master/blur), bindings, base flags
    ├── fontconfig/fonts.conf    JetBrainsMono Nerd Font
    ├── ghostty/config           terminal font/size/padding/keybinds
    ├── kitty/kitty.conf         terminal font/padding/opacity/tab style
    ├── fastfetch/               config + custom Linux logo (path auto-rewritten)
    ├── plugins/rob.*            bar, clock, menu, menubutton, workspaces, updates widgets
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
| Icons | Yaru-magenta |
| Wallpaper | `default.png` |

## Notes

- The bar plugins (`rob.bar`, `rob.clock`, `rob.workspaces`) are local edits of
  Omarchy's built-ins, vendored as-is. They won't pick up future `omarchy update`
  improvements to the originals.
- `rob.menu` is a vendored clone of the built-in `omarchy.menu` (kept as a fixed
  id so `shell.json` and `rob.menubutton` can reference it regardless of username);
  it won't pick up future changes to `omarchy.menu`.
- `keyboard.rgb` only takes effect if your keyboard-RGB tool reads Omarchy's theme
  file; the script can't force it.
- fastfetch's logo is bundled and its path is rewritten at install, so there are no
  machine-specific absolute paths in this repo.
- Non-look personal settings (git identity, monitors, input) are intentionally not
  included.
