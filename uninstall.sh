#!/bin/bash
# Removes Greengo's hooks, status line, desktop mod, /greengo command, VS Code extension, and files.
set -e
DEST="$HOME/.claude/greengo"
python3 "$DEST/merge_settings.py" uninstall "$HOME/.claude/settings.json" "$DEST"
for c in code "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
         "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
  if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then
    "$c" --uninstall-extension greengo-local.greengo >/dev/null 2>&1 || true
    break
  fi
done
rm -rf "$HOME/.claude/skills/greengo" "$DEST"
echo "👋 Greengo has ridden off for good. (A backup of your settings is next to settings.json.)"
