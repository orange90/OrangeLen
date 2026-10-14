#!/bin/bash
# macOS 26's Hydra preview takes precedence over third-party STL/OBJ previews.
# Change only this user's election; preserve the previous election for undo.
set -euo pipefail
identifier=com.apple.HydraQLPreviewExtension
state_dir="$HOME/Library/Application Support/OrangeLen"
state_file="$state_dir/mesh-preview-election"
listing=$(/usr/bin/pluginkit -m -i "$identifier")
if [[ -z "$listing" ]]; then
  echo "Hydra is not registered on this Mac; no setting changed."
  exit 0
fi
case "${1:-status}" in
  status)
    printf '%s\n' "$listing"
    if [[ -f "$state_file" ]]; then echo "Previous election saved for restore."; fi
    ;;
  enable)
    if [[ ! -f "$state_file" ]]; then
      case "${listing:0:1}" in
        '+') election=use ;;
        '-') election=ignore ;;
        ' ') election=default ;;
        *) echo "Unknown Hydra election; refusing to overwrite it." >&2; exit 1 ;;
      esac
      mkdir -p "$state_dir"
      (umask 077; printf '%s\n' "$election" > "$state_file")
    fi
    /usr/bin/pluginkit -e ignore -i "$identifier"
    /usr/bin/qlmanage -r
    echo "OrangeLen can now preview STL/OBJ. Close and reopen Quick Look."
    echo "Hydra also handles PLY, USD, MaterialX and Alembic; their system fallback may differ."
    ;;
  restore)
    if [[ ! -f "$state_file" ]]; then
      echo "No saved election; no setting changed." >&2
      exit 1
    fi
    election=$(cat "$state_file")
    case "$election" in use|ignore|default) ;; *) echo "Invalid saved election." >&2; exit 1 ;; esac
    /usr/bin/pluginkit -e "$election" -i "$identifier"
    /usr/bin/qlmanage -r
    rm "$state_file"
    echo "Restored the previous Hydra election. Close and reopen Quick Look."
    ;;
  *) echo "Usage: $0 [status|enable|restore]" >&2; exit 2 ;;
esac
