#!/bin/bash
# Select OrangeLen for workflow files on macOS versions that prefer Shortcuts.
# Preserve the user's prior election so this preference can be undone exactly.
set -euo pipefail
identifier=com.apple.shortcuts.QuickLookExtension
state_dir="$HOME/Library/Application Support/OrangeLen"
state_file="$state_dir/workflow-preview-election"
listing=$(/usr/bin/pluginkit -m -i "$identifier")
if [[ -z "$listing" ]]; then
  echo "Shortcuts preview is not registered on this Mac; no setting changed."
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
        *) echo "Unknown Shortcuts election; refusing to overwrite it." >&2; exit 1 ;;
      esac
      mkdir -p "$state_dir"
      (umask 077; printf '%s\n' "$election" > "$state_file")
    fi
    /usr/bin/pluginkit -e ignore -i "$identifier"
    /usr/bin/qlmanage -r
    echo "OrangeLen workflow preview preference enabled. Close and reopen Quick Look."
    echo "This also disables Apple's action-card preview for .shortcut files."
    echo "Run this script with restore to recover the previous election."
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
    echo "Restored the previous Shortcuts election. Close and reopen Quick Look."
    ;;
  *) echo "Usage: $0 [status|enable|restore]" >&2; exit 2 ;;
esac
