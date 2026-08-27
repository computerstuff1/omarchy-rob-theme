#!/usr/bin/env bash
#
# omarchy-rob-theme — install the "Rob Theme" look on an Omarchy system.
#
# Idempotent and safe to re-run: the first run saves timestamped backups of
# anything it overwrites; later runs just refresh to this repo's state. It
# never deletes anything that isn't staged here.
#
# Usage:
#   ./install.sh            # interactive (with dependency installs)
#   ./install.sh --yes      # non-interactive; skip confirmations
#   ./install.sh --no-deps  # skip the package install step entirely

set -euo pipefail

ASSUME_YES=0
INSTALL_DEPS=1
for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --no-deps) INSTALL_DEPS=0 ;;
    -h|--help)
      echo "Usage: $0 [--yes] [--no-deps]"
      exit 0
      ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_CFG="$HOME/.config/omarchy"
THEME_SLUG="rob-theme"
THEME_NAME="Rob Theme"
THEME_DIR="$OMARCHY_CFG/themes/$THEME_SLUG"
FASTFETCH_LOGO_DIR="$HOME/.local/share/omarchy-rob-theme"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.cache/omarchy-rob-theme/backup/$TS"

info()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()    { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m  !\033[0m %s\n' "$*"; }

confirm() {
  local prompt="$1"
  if (( ASSUME_YES )); then return 0; fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

# guard: this only makes sense on Omarchy
if [[ -z "${OMARCHY_PATH:-}" ]]; then
  OMARCHY_PATH="$(command -v omarchy >/dev/null 2>&1 && dirname "$(dirname "$(readlink -f "$(command -v omarchy)")")" || true)"
fi
if ! command -v omarchy >/dev/null 2>&1; then
  echo "omarchy CLI not found — this script targets an Omarchy install." >&2
  exit 1
fi

# back up an existing path before overwriting, preserving repo-relative layout
backup() {
  local rel="$1" target="$2"
  if [[ -e "$target" || -L "$target" ]]; then
    mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
    cp -a "$target" "$BACKUP_ROOT/$rel" 2>/dev/null || true
    ok "backed up $(basename "$target")"
  fi
}

info "Omarchy Rob Theme installer"
info "Backups (if any) go to: $BACKUP_ROOT"

if (( INSTALL_DEPS )); then
  info "Step 1/6 — installing dependencies"
  omarchy pkg add pacman-contrib || warn "pacman-contrib install failed (update count may be repo-only)"
  omarchy pkg aur add yaru-icon-theme || warn "Yaru icon theme unavailable (icons fall back to default)"
  omarchy pkg aur add yay || warn "yay unavailable (AUR update count will be skipped)"
else
  info "Step 1/6 — skipping dependency install (--no-deps)"
fi

info "Step 2/6 — staging theme '$THEME_NAME'"
backup "themes/$THEME_SLUG" "$THEME_DIR"
mkdir -p "$THEME_DIR/backgrounds"
cp "$REPO_DIR/theme/colors.toml"      "$THEME_DIR/colors.toml"
cp "$REPO_DIR/theme/shell.bar.toml"    "$THEME_DIR/shell.bar.toml"
cp "$REPO_DIR/theme/shell.lock.toml"   "$THEME_DIR/shell.lock.toml"
cp "$REPO_DIR/theme/icons.theme"       "$THEME_DIR/icons.theme"
cp "$REPO_DIR/theme/keyboard.rgb"      "$THEME_DIR/keyboard.rgb"
cp "$REPO_DIR/backgrounds/default.png" "$THEME_DIR/backgrounds/default.png"
ok "theme staged at $THEME_DIR"

info "Step 3/6 — applying theme"
omarchy theme set "$THEME_NAME"

info "Step 4/6 — installing dotfiles"

# bar layout + shell gradient overrides
backup "dotfiles/shell.json" "$OMARCHY_CFG/shell.json"
backup "dotfiles/shell.toml" "$OMARCHY_CFG/shell.toml"
cp "$REPO_DIR/dotfiles/shell.json" "$OMARCHY_CFG/shell.json"
cp "$REPO_DIR/dotfiles/shell.toml" "$OMARCHY_CFG/shell.toml"

# starship prompt
backup "dotfiles/starship.toml" "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config"
cp "$REPO_DIR/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"

# Hyprland look (borders, gaps, master layout, blur) + bindings + base flags
for f in looknfeel.lua bindings.lua hyprland.lua; do
  backup "hypr/$f" "$HOME/.config/hypr/$f"
  mkdir -p "$HOME/.config/hypr"
  cp "$REPO_DIR/dotfiles/hypr/$f" "$HOME/.config/hypr/$f"
done

# fontconfig monospace binding
backup "fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"
mkdir -p "$HOME/.config/fontconfig"
cp "$REPO_DIR/dotfiles/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# ghostty terminal
backup "ghostty/config" "$HOME/.config/ghostty/config"
mkdir -p "$HOME/.config/ghostty"
cp "$REPO_DIR/dotfiles/ghostty/config" "$HOME/.config/ghostty/config"

# kitty terminal
backup "kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
mkdir -p "$HOME/.config/kitty"
cp "$REPO_DIR/dotfiles/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# vim
backup "vimrc" "$HOME/.vimrc"
backup "vim/colors" "$HOME/.vim/colors" 2>/dev/null || true
cp "$REPO_DIR/dotfiles/vim/vimrc" "$HOME/.vimrc"
mkdir -p "$HOME/.vim/colors"
cp "$REPO_DIR/dotfiles/vim/colors/catppuccin_mocha.vim" "$HOME/.vim/colors/catppuccin_mocha.vim"

# update-count helper
backup "bin/system-update-count" "$OMARCHY_CFG/bin/system-update-count"
mkdir -p "$OMARCHY_CFG/bin"
cp "$REPO_DIR/dotfiles/bin/system-update-count" "$OMARCHY_CFG/bin/system-update-count"
chmod +x "$OMARCHY_CFG/bin/system-update-count"

# fastfetch (logo path is rewritten to the bundled asset)
backup "fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
backup "fastfetch/Linux.png" "$FASTFETCH_LOGO_DIR/Linux.png"
mkdir -p "$HOME/.config/fastfetch" "$FASTFETCH_LOGO_DIR"
cp "$REPO_DIR/dotfiles/fastfetch/Linux.png" "$FASTFETCH_LOGO_DIR/Linux.png"
sed "s|@LOGO_PATH@|$FASTFETCH_LOGO_DIR/Linux.png|" \
  "$REPO_DIR/dotfiles/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"

# bar plugins
for p in rob.bar rob.clock rob.menu rob.menubutton rob.workspaces rob.updates; do
  backup "plugins/$p" "$OMARCHY_CFG/plugins/$p"
  mkdir -p "$OMARCHY_CFG/plugins"
  rm -rf "$OMARCHY_CFG/plugins/$p"
  cp -r "$REPO_DIR/dotfiles/plugins/$p" "$OMARCHY_CFG/plugins/$p"
done
ok "dotfiles installed"

info "Step 5/6 — registering widgets"
omarchy-shell shell rescanPlugins || warn "rescan failed (is the shell running?)"
for id in rob.bar rob.clock rob.menu rob.menubutton rob.workspaces rob.updates; do
  omarchy plugin enable "$id" 2>/dev/null || true
done
ok "widgets registered"

info "Step 6/6 — reloading"
omarchy restart shell 2>/dev/null || warn "could not restart shell"
hyprctl reload 2>/dev/null || warn "could not reload Hyprland"

echo
ok "Done. Verify with: omarchy theme current && hyprctl configerrors"
