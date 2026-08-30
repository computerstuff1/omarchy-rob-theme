#!/usr/bin/env bash
#
# omarchy-rob-theme post-update hook.
#
# Re-applies the Rob Theme bar + clock patches after `omarchy update`, so the
# de-forked clones pick up upstream improvements instead of freezing at
# install-time state. The look survives an update even when a patch can no
# longer apply: the patch is applied to a scratch copy first and only swapped
# in on success, so the last-good clone stays in place (never a broken bar).
set -uo pipefail

OMARCHY_CFG="${HOME}/.config/omarchy"
STASH="${OMARCHY_CFG}/rob-theme/patches"

# Rewrite a cloned manifest so it registers under the fixed `rob.*` id while
# keeping `clonedFrom` so the shell routes IPC to the correct widget.
rewrite_manifest() {
  local manifest="$1" dst_id="$2" name="$3" src_id="$4"
  if command -v jq >/dev/null 2>&1; then
    jq --arg id "$dst_id" --arg name "$name" --arg src "$src_id" \
      '.id = $id | .name = $name | if (.barWidget | type) == "object" then .barWidget.displayName = $name else . end | .omarchy = ((.omarchy // {}) + {clonedFrom: $src})' \
      "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
  else
    sed -i "s/\"id\": *\"$src_id\"/\"id\": \"$dst_id\"/" "$manifest"
  fi
}

repatch() {
  local src_id="$1" dst_id="$2" name="$3" patchfile="$4"
  local src_dir dst tmp

  src_dir="$(omarchy-plugin-catalog 2>/dev/null | jq -r --arg id "$src_id" '.[] | select(.id == $id) | .sourceDir' | head -n1)"
  [[ -n "$src_dir" && "$src_dir" != "null" ]] || return
  dst="${OMARCHY_CFG}/plugins/${dst_id}"
  [[ -f "${STASH}/${patchfile}" ]] || return

  # Clone into a scratch dir and patch there first; only swap into place if the
  # patch applies cleanly. This leaves the last-good clone intact on failure.
  tmp="$(mktemp -d "${dst}.tmp.XXXXXX")" || return
  cp -a "$src_dir"/. "$tmp"/

  rewrite_manifest "$tmp/manifest.json" "$dst_id" "$name" "$src_id"

  if ! patch -p1 -d "$tmp" < "${STASH}/${patchfile}" >/dev/null; then
    echo "rob-theme: $dst_id patch failed after update — re-base $patchfile (keeping last-good clone)" >&2
    rm -rf "$tmp"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  mv "$tmp" "$dst"
}

repatch omarchy.bar   rob.bar   "My Bar"   bar.patch
repatch omarchy.clock rob.clock "My Clock" clock.patch
