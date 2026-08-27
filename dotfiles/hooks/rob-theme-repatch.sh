#!/usr/bin/env bash
#
# omarchy-rob-theme post-update hook.
#
# Re-applies the Rob Theme bar + clock patches after `omarchy update`, so the
# de-forked clones pick up upstream improvements instead of freezing at
# install-time state. The look survives an update even when a patch can no
# longer apply: the last-good clone is left in place and a warning is printed.
set -u

OMARCHY_CFG="${HOME}/.config/omarchy"
STASH="${OMARCHY_CFG}/rob-theme/patches"

repatch() {
  local src_id="$1" dst_id="$2" name="$3" patchfile="$4"
  local src_dir dst

  src_dir="$(omarchy-plugin-catalog 2>/dev/null | jq -r --arg id "$src_id" '.[] | select(.id == $id) | .sourceDir' | head -n1)"
  [[ -n "$src_dir" && "$src_dir" != "null" ]] || return
  dst="${OMARCHY_CFG}/plugins/${dst_id}"
  [[ -f "${STASH}/${patchfile}" ]] || return

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src_dir" "$dst"

  jq --arg id "$dst_id" --arg name "$name" --arg src "$src_id" \
    '.id = $id | .name = $name | if (.barWidget | type) == "object" then .barWidget.displayName = $name else . end | .omarchy = ((.omarchy // {}) + {clonedFrom: $src})' \
    "$dst/manifest.json" > "$dst/manifest.json.tmp" && mv "$dst/manifest.json.tmp" "$dst/manifest.json"

  if ! patch -p1 -d "$dst" < "${STASH}/${patchfile}" >/dev/null; then
    echo "rob-theme: $dst_id patch failed after update — re-base $patchfile" >&2
  fi
}

repatch omarchy.bar   rob.bar   "My Bar"   bar.patch
repatch omarchy.clock rob.clock "My Clock" clock.patch
