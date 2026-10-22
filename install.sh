#!/bin/bash
# Installs Greengo into ~/.claude (with his desktop mod and VS Code extension). Safe to run again to update.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.claude/greengo"
SETTINGS="$HOME/.claude/settings.json"

echo "🤠 Installing Greengo…"

if ! python3 -c 'import json' >/dev/null 2>&1; then
  echo "✋ Greengo's installer needs python3 to edit your settings safely."
  echo "   On a Mac, run:  xcode-select --install   then run this installer again."
  exit 1
fi

mkdir -p "$DEST/state" "$HOME/.claude/skills/greengo"
cp "$HERE/greengo.sh" "$DEST/greengo.sh"
cp "$HERE/merge_settings.py" "$DEST/merge_settings.py"
cp "$HERE/uninstall.sh" "$DEST/uninstall.sh"
cp "$HERE/skill/SKILL.md" "$HOME/.claude/skills/greengo/SKILL.md"
# The Claude desktop app mod: Greengo above the prompt in the Code tab.
rm -rf "$DEST/desktop"
mkdir -p "$DEST/desktop/.claude-plugin" "$DEST/desktop/hooks" "$DEST/desktop/types"
cp "$HERE/desktop/.claude-plugin/plugin.json" "$DEST/desktop/.claude-plugin/"
cp "$HERE/desktop/hooks/hooks.json" "$HERE/desktop/hooks/register.tsx" "$DEST/desktop/hooks/"
cp "$HERE/desktop/types/index.d.ts" "$DEST/desktop/types/"
chmod +x "$DEST/greengo.sh" "$DEST/uninstall.sh"

python3 "$DEST/merge_settings.py" install "$SETTINGS" "$DEST"
echo "  ✓ hooks, terminal status line and Claude desktop app mod"

# The VS Code extension: Greengo in the status bar and in his own panel.
find_code() {
  for c in code "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
           "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
           "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then echo "$c"; return 0; fi
  done
  return 1
}
if [ -f "$HERE/greengo.vsix" ]; then
  cp "$HERE/greengo.vsix" "$DEST/greengo.vsix"
  if CODE=$(find_code) && "$CODE" --install-extension "$DEST/greengo.vsix" --force >/dev/null 2>&1; then
    echo "  ✓ VS Code extension (reload VS Code to see him: Cmd+Shift+P → 'Developer: Reload Window')"
  else
    echo "  ✋ Couldn't install the VS Code extension automatically. In VS Code: Extensions view →"
    echo "     '…' menu → 'Install from VSIX…' → pick $DEST/greengo.vsix"
  fi
fi

echo "✅ Done! Yeehaw."
echo "   VS Code: Greengo rides in the status bar; click him (or Cmd+Shift+P → 'Greengo: Show panel') for the full look."
echo "   Terminal: run 'claude' to see him in the status line."
echo "   Claude desktop app: start a new Code session and he rides above the prompt."
echo "   Try:  /greengo name Tex   ·   /greengo color cyan   ·   /greengo stats"
echo "   Uninstall any time:  ~/.claude/greengo/uninstall.sh"
