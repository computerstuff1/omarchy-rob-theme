#!/usr/bin/env bash
#
# omarchy-rob-theme — install the "Rob Theme" look on an Omarchy system.
#
# Idempotent and safe to re-run: the first run saves timestamped backups of
# anything it overwrites; later runs just refresh to this repo's state. It
# never deletes anything that isn't staged here.
#
# Usage:
#   ./install.sh              # interactive (with confirmations + dependency installs)
#   ./install.sh --yes        # non-interactive; skip confirmations
#   ./install.sh --no-deps    # skip the package install step entirely
#   ./install.sh --aur-helper=paru|yay|none   # choose the AUR helper (default: yay)
#   ./install.sh --uninstall  # restore the most recent backup + remove our changes
#   ./install.sh --restore=TS # restore a specific backup (see ~/.cache/omarchy-rob-theme/backup/)

set -euo pipefail

ASSUME_YES=0
INSTALL_DEPS=1
AUR_HELPER="yay"
UNINSTALL=0
RESTORE_TS=""
BACKUP_KEEP=5

for arg in "$@"; do
  case "$arg" in
    --yes|-y) ASSUME_YES=1 ;;
    --no-deps) INSTALL_DEPS=0 ;;
    --aur-helper=*) AUR_HELPER="${arg#*=}" ;;
    --uninstall) UNINSTALL=1 ;;
    --restore=*) RESTORE_TS="${arg#*=}" ;;
    -h|--help)
      echo "Usage: $0 [--yes] [--no-deps] [--aur-helper=yay|paru|none] [--uninstall] [--restore=TS]"
      exit 0
      ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

case "$AUR_HELPER" in
  yay|paru|none) ;;
  *) echo "invalid --aur-helper '$AUR_HELPER' (expected yay, paru, or none)" >&2; exit 1 ;;
esac

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
  OMARCHY_PATH=""
  if omarchy_bin="$(command -v omarchy)"; then
    OMARCHY_PATH="$(dirname "$(dirname "$(readlink -f "$omarchy_bin")")")"
  fi
fi
if ! command -v omarchy >/dev/null 2>&1; then
  echo "omarchy CLI not found — this script targets an Omarchy install." >&2
  exit 1
fi

# back up an existing path before overwriting. When `src` is given, skip the
# backup if `target` is already byte-identical to the source (avoids spamming
# ~/.cache with no-op backups on re-runs).
backup() {
  local rel="$1" target="$2" src="${3:-}"
  if [[ ! -e "$target" && ! -L "$target" ]]; then return 0; fi
  if [[ -n "$src" ]]; then
    if [[ -d "$src" ]]; then
      diff -rq "$src" "$target" >/dev/null 2>&1 && return 0
    else
      cmp -s "$src" "$target" 2>/dev/null && return 0
    fi
  fi
  mkdir -p "$BACKUP_ROOT/$(dirname "$rel")"
  cp -a "$target" "$BACKUP_ROOT/$rel" 2>/dev/null || true
  ok "backed up $(basename "$target")"
}

# Install a package only if the binary it provides isn't already present.
# Usage: ensure_pkg <probe-binary> <install-cmd...>
ensure_pkg() {
  local bin="$1"; shift
  if command -v "$bin" >/dev/null 2>&1; then
    ok "$bin already installed"
    return 0
  fi
  "$@"
}

# Clone the *current* built-in plugin into a fixed, portable id, then re-apply a
# minimal patch. This keeps the custom look while inheriting any improvements
# that land in the built-in on `omarchy update`, instead of freezing a vendored
# copy that silently drifts. Internal ids (clonedFrom) are preserved so the
# shell keeps routing IPC to the correct widget.
clone_builtin() {
  local src_id="$1" dst_id="$2" name="$3" patchfile="$4"
  local src_dir
  src_dir="$(omarchy-plugin-catalog 2>/dev/null | jq -r --arg id "$src_id" '.[] | select(.id == $id) | .sourceDir' | head -n1)"
  if [[ -z "$src_dir" || "$src_dir" == "null" ]]; then
    warn "cannot locate built-in \"$src_id\" — skipping $dst_id"
    return 1
  fi
  local dst="$OMARCHY_CFG/plugins/$dst_id"
  backup "plugins/$dst_id" "$dst"
  mkdir -p "$OMARCHY_CFG/plugins"
  rm -rf "$dst"
  cp -a "$src_dir" "$dst"
  if command -v jq >/dev/null 2>&1; then
    jq --arg id "$dst_id" --arg name "$name" --arg src "$src_id" \
      '.id = $id | .name = $name | if (.barWidget | type) == "object" then .barWidget.displayName = $name else . end | .omarchy = ((.omarchy // {}) + {clonedFrom: $src})' \
      "$dst/manifest.json" > "$dst/manifest.json.tmp" && mv "$dst/manifest.json.tmp" "$dst/manifest.json"
  else
    sed -i "s/\"id\": \"$src_id\"/\"id\": \"$dst_id\"/" "$dst/manifest.json"
  fi
  if [[ -n "$patchfile" && -f "$REPO_DIR/$patchfile" ]]; then
    if patch -p1 -d "$dst" < "$REPO_DIR/$patchfile" >/dev/null; then
      ok "cloned $src_id -> $dst_id (patched)"
    else
      warn "patch $patchfile failed to apply — built-in \"$src_id\" changed upstream; re-base this patch"
    fi
  else
    ok "cloned $src_id -> $dst_id"
  fi
}

# Keep only the newest N backups under ~/.cache/omarchy-rob-theme/backup.
prune_backups() {
  local parent="$HOME/.cache/omarchy-rob-theme/backup" n=0 d
  [[ -d "$parent" ]] || return 0
  while IFS= read -r d; do
    n=$((n + 1))
    if (( n > ${1:-$BACKUP_KEEP} )); then rm -rf -- "${parent:?}/${d:?}"; fi
  done < <(find "$parent" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r)
}

# Map a backup's repo-relative path back to where it was installed.
target_for() {
  local rel="$1"
  case "$rel" in
    themes/rob-theme)           printf '%s\n' "$THEME_DIR" ;;
    dotfiles/shell.json)        printf '%s\n' "$OMARCHY_CFG/shell.json" ;;
    dotfiles/starship.toml)     printf '%s\n' "$HOME/.config/starship.toml" ;;
    hypr/*)                     printf '%s\n' "$HOME/.config/$rel" ;;
    fontconfig/*)               printf '%s\n' "$HOME/.config/$rel" ;;
    kitty/*)                    printf '%s\n' "$HOME/.config/$rel" ;;
    vimrc)                      printf '%s\n' "$HOME/.vimrc" ;;
    vim/colors)                 printf '%s\n' "$HOME/.vim/colors" ;;
    vim/autoload)               printf '%s\n' "$HOME/.vim/autoload" ;;
    bin/system-update-count)    printf '%s\n' "$OMARCHY_CFG/bin/system-update-count" ;;
    fastfetch/config.jsonc)     printf '%s\n' "$HOME/.config/fastfetch/config.jsonc" ;;
    fastfetch/Linux.png)        printf '%s\n' "$FASTFETCH_LOGO_DIR/Linux.png" ;;
    plugins/*)                  printf '%s\n' "$OMARCHY_CFG/plugins/${rel#plugins/}" ;;
    *)                          return 1 ;;
  esac
}

# Restore a backup (latest by default, or a specific timestamp with --restore).
# For each path we manage: if a backup exists, put it back; if not, the path
# didn't exist before install, so remove what we added.
do_uninstall() {
  local parent="$HOME/.cache/omarchy-rob-theme/backup" dir
  if [[ -n "$RESTORE_TS" ]]; then
    dir="$parent/$RESTORE_TS"
  else
    dir="$(find "$parent" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n1)"
    [[ -n "$dir" ]] && dir="$parent/$dir"
  fi
  dir="${dir%/}"
  if [[ -z "$dir" || ! -d "$dir" ]]; then
    warn "no backup found to restore (run install.sh at least once first)"
    return 1
  fi

  info "Restoring from $(basename "$dir")"

  rm -f "$OMARCHY_CFG/hooks/post-update.d/rob-theme-repatch.sh"
  for id in rob.bar rob.clock rob.menubutton rob.workspaces rob.updates; do
    omarchy plugin disable "$id" 2>/dev/null || true
  done

  local rels=(
    themes/rob-theme dotfiles/shell.json dotfiles/starship.toml
    hypr/looknfeel.lua hypr/bindings.lua hypr/hyprland.lua
    fontconfig/fonts.conf kitty/kitty.conf kitty/current-theme.conf
    vimrc vim/colors vim/autoload
    bin/system-update-count fastfetch/config.jsonc fastfetch/Linux.png
    plugins/rob.menubutton plugins/rob.workspaces plugins/rob.updates
    plugins/rob.bar plugins/rob.clock
  )

  local rel target
  for rel in "${rels[@]}"; do
    target="$(target_for "$rel")" || continue
    if [[ -e "$dir/$rel" || -L "$dir/$rel" ]]; then
      mkdir -p "$(dirname "$target")"
      rm -rf "$target"
      cp -a "$dir/$rel" "$target"
      ok "restored $rel"
    else
      rm -rf "$target"
      ok "removed $rel"
    fi
  done

  rm -rf "$OMARCHY_CFG/rob-theme"
  ok "removed repatch stash + hook"

  omarchy restart shell 2>/dev/null || warn "could not restart shell"
  hyprctl reload 2>/dev/null || warn "could not reload Hyprland"
  echo
  ok "Uninstalled. Backups remain under $parent if you need them."
}

if (( UNINSTALL )); then
  do_uninstall
  exit 0
fi

info "Omarchy Rob Theme installer"
info "Backups (if needed) go to: $BACKUP_ROOT"

if (( INSTALL_DEPS )); then
  confirm "Install missing dependencies?" || { info "Skipping dependency install"; INSTALL_DEPS=0; }
fi
confirm "Proceed with installation?" || { echo "Aborted."; exit 0; }

if (( INSTALL_DEPS )); then
  info "Step 1/6 — installing dependencies"
  ensure_pkg checkupdates           omarchy pkg add pacman-contrib || warn "pacman-contrib install failed (update count will be repo-only)"
  ensure_pkg jq                     omarchy pkg add jq              || warn "jq install failed (floating bar/clock clones will be skipped)"
  ensure_pkg gvim                   omarchy pkg add gvim            || warn "gvim install failed"
  ensure_pkg kitty                  omarchy pkg add kitty           || warn "kitty install failed"
  ensure_pkg firefox                omarchy pkg add firefox         || warn "firefox install failed"
  if omarchy pkg present ttf-jetbrains-mono-nerd-basic; then
    ok "JetBrainsMono Nerd Font already installed"
  else
    omarchy pkg add ttf-jetbrains-mono-nerd-basic || warn "JetBrainsMono Nerd Font install failed (fallback font will be used)"
  fi
  if [[ -d /usr/share/icons/Yaru-red ]]; then
    ok "Yaru-red icons already installed"
  else
    omarchy pkg aur add yaru-icon-theme || warn "Yaru icon theme unavailable (icons fall back to default)"
  fi
  if [[ "$AUR_HELPER" != "none" ]]; then
    ensure_pkg "$AUR_HELPER" omarchy pkg aur add "$AUR_HELPER" || warn "$AUR_HELPER unavailable (AUR update count will be skipped)"
  fi
else
  info "Step 1/6 — skipping dependency install (--no-deps)"
fi

info "Step 2/6 — staging theme '$THEME_NAME'"
backup "themes/$THEME_SLUG" "$THEME_DIR"
mkdir -p "$THEME_DIR/backgrounds"
cp "$REPO_DIR/theme/colors.toml"      "$THEME_DIR/colors.toml"
cp "$REPO_DIR/theme/shell.bar.toml"    "$THEME_DIR/shell.bar.toml"
cp "$REPO_DIR/theme/shell.lock.toml"   "$THEME_DIR/shell.lock.toml"
cp "$REPO_DIR/theme/shell.menu.toml"   "$THEME_DIR/shell.menu.toml"
cp "$REPO_DIR/theme/icons.theme"       "$THEME_DIR/icons.theme"
rm -f "$THEME_DIR/keyboard.rgb"
cp "$REPO_DIR/backgrounds/default.png" "$THEME_DIR/backgrounds/default.png"
ok "theme staged at $THEME_DIR"

info "Step 3/6 — applying theme"
if ! omarchy theme set "$THEME_NAME"; then
  warn "omarchy theme set returned an error — check 'omarchy theme current'"
else
  ok "theme applied"
fi

info "Step 4/6 — installing dotfiles"

# bar layout
backup "dotfiles/shell.json" "$OMARCHY_CFG/shell.json" "$REPO_DIR/dotfiles/shell.json"
cp "$REPO_DIR/dotfiles/shell.json" "$OMARCHY_CFG/shell.json"

# starship prompt
backup "dotfiles/starship.toml" "$HOME/.config/starship.toml" "$REPO_DIR/dotfiles/starship/starship.toml"
mkdir -p "$HOME/.config"
cp "$REPO_DIR/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"

# Hyprland look (borders, gaps, master layout, blur) + bindings + base flags
for f in looknfeel.lua bindings.lua hyprland.lua; do
  backup "hypr/$f" "$HOME/.config/hypr/$f" "$REPO_DIR/dotfiles/hypr/$f"
  mkdir -p "$HOME/.config/hypr"
  cp "$REPO_DIR/dotfiles/hypr/$f" "$HOME/.config/hypr/$f"
done

# fontconfig monospace binding
backup "fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf" "$REPO_DIR/dotfiles/fontconfig/fonts.conf"
mkdir -p "$HOME/.config/fontconfig"
cp "$REPO_DIR/dotfiles/fontconfig/fonts.conf" "$HOME/.config/fontconfig/fonts.conf"

# kitty terminal (Catppuccin palette via current-theme.conf overrides the theme)
backup "kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" "$REPO_DIR/dotfiles/kitty/kitty.conf"
backup "kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf" "$REPO_DIR/dotfiles/kitty/current-theme.conf"
mkdir -p "$HOME/.config/kitty"
cp "$REPO_DIR/dotfiles/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp "$REPO_DIR/dotfiles/kitty/current-theme.conf" "$HOME/.config/kitty/current-theme.conf"

# vim
backup "vimrc" "$HOME/.vimrc" "$REPO_DIR/dotfiles/vim/vimrc"
backup "vim/colors" "$HOME/.vim/colors" "$REPO_DIR/dotfiles/vim/colors" 2>/dev/null || true
backup "vim/autoload" "$HOME/.vim/autoload" "$REPO_DIR/dotfiles/vim/autoload"
cp "$REPO_DIR/dotfiles/vim/vimrc" "$HOME/.vimrc"
mkdir -p "$HOME/.vim/colors"
cp "$REPO_DIR/dotfiles/vim/colors/catppuccin_mocha.vim" "$HOME/.vim/colors/catppuccin_mocha.vim"
mkdir -p "$HOME/.vim/autoload"
cp -r "$REPO_DIR/dotfiles/vim/autoload/." "$HOME/.vim/autoload/"

# update-count helper
backup "bin/system-update-count" "$OMARCHY_CFG/bin/system-update-count" "$REPO_DIR/dotfiles/bin/system-update-count"
mkdir -p "$OMARCHY_CFG/bin"
cp "$REPO_DIR/dotfiles/bin/system-update-count" "$OMARCHY_CFG/bin/system-update-count"
chmod +x "$OMARCHY_CFG/bin/system-update-count"

# fastfetch (logo path is rewritten to the bundled asset)
backup "fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
backup "fastfetch/Linux.png" "$FASTFETCH_LOGO_DIR/Linux.png" "$REPO_DIR/dotfiles/fastfetch/Linux.png"
mkdir -p "$HOME/.config/fastfetch" "$FASTFETCH_LOGO_DIR"
cp "$REPO_DIR/dotfiles/fastfetch/Linux.png" "$FASTFETCH_LOGO_DIR/Linux.png"
sed "s|@LOGO_PATH@|$FASTFETCH_LOGO_DIR/Linux.png|" \
  "$REPO_DIR/dotfiles/fastfetch/config.jsonc" > "$HOME/.config/fastfetch/config.jsonc"

# self-contained widgets ship as-is
for p in rob.menubutton rob.workspaces rob.updates; do
  backup "plugins/$p" "$OMARCHY_CFG/plugins/$p" "$REPO_DIR/dotfiles/plugins/$p"
  mkdir -p "$OMARCHY_CFG/plugins"
  rm -rf "$OMARCHY_CFG/plugins/$p"
  cp -r "$REPO_DIR/dotfiles/plugins/$p" "$OMARCHY_CFG/plugins/$p"
done

# de-forked built-ins (floating bar + seconds clock): clone the current
# built-in, then re-apply a minimal patch so updates are inherited, not frozen.
clone_builtin omarchy.bar   rob.bar   "My Bar"   patches/bar.patch   || warn "rob.bar clone failed"
clone_builtin omarchy.clock rob.clock "My Clock" patches/clock.patch || warn "rob.clock clone failed"

# stash the patches somewhere stable so the post-update hook can re-apply them
mkdir -p "$OMARCHY_CFG/rob-theme/patches"
cp "$REPO_DIR/patches/bar.patch"   "$OMARCHY_CFG/rob-theme/patches/bar.patch"
cp "$REPO_DIR/patches/clock.patch" "$OMARCHY_CFG/rob-theme/patches/clock.patch"

# re-apply the de-forked look after every `omarchy update`
if command -v omarchy >/dev/null 2>&1 && omarchy hook --help >/dev/null 2>&1; then
  omarchy hook install post-update "$REPO_DIR/dotfiles/hooks/rob-theme-repatch.sh" || warn "could not install post-update hook"
fi
ok "dotfiles installed"

info "Step 5/6 — registering widgets"
omarchy-shell shell rescanPlugins || warn "rescan failed (is the shell running?)"
for id in rob.bar rob.clock rob.menubutton rob.workspaces rob.updates; do
  omarchy plugin enable "$id" 2>/dev/null || true
done
ok "widgets registered"

info "Step 6/6 — reloading"
omarchy restart shell 2>/dev/null || warn "could not restart shell"
hyprctl reload 2>/dev/null || warn "could not reload Hyprland"

prune_backups "$BACKUP_KEEP"

echo
ok "Done. Verify with: omarchy theme current && hyprctl configerrors"
