#!/bin/bash
# Smoke test: installs Greengo into a throwaway home folder, plays a short
# Claude Code session through his hooks, checks what he draws, then uninstalls.
# Nothing touches your real ~/.claude.   Run:  bash tests/smoke.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export HOME="$(mktemp -d)"
trap 'rm -rf "$HOME"' EXIT
mkdir -p "$HOME/.claude"
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); echo "  ✓ $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# A pre-existing setting and status line that Greengo must leave alone / restore.
cat > "$HOME/.claude/settings.json" <<'EOF'
{ "model": "opus", "statusLine": { "type": "command", "command": "~/my-old-statusline.sh" },
  "env": { "CLAUDE_CODE_PLUGIN_DIRS": "~/my-mods" } }
EOF

echo "Install"
bash "$ROOT/install.sh" >/dev/null 2>&1
G="$HOME/.claude/greengo/greengo.sh"
S="$HOME/.claude/settings.json"
check "script installed"            "[ -x '$G' ]"
check "/greengo command installed"  "[ -f '$HOME/.claude/skills/greengo/SKILL.md' ]"
check "status line points at Greengo" "grep -q 'greengo.sh\\\\\" status' '$S'"
check "hooks registered"            "[ \$(grep -c 'greengo.sh\\\\\" hook' '$S') -ge 10 ]"
check "other settings kept"         "grep -q '\"model\": \"opus\"' '$S'"
check "desktop mod installed"       "[ -f '$HOME/.claude/greengo/desktop/hooks/register.tsx' ] && [ -f '$HOME/.claude/greengo/desktop/.claude-plugin/plugin.json' ]"
check "desktop mod registered"      "grep -q '\"CLAUDE_CODE_PLUGIN_DIRS\": \"~/my-mods:~/.claude/greengo/desktop\"' '$S'"
bash "$ROOT/install.sh" >/dev/null 2>&1
check "reinstall registers it once" "[ \$(grep -o 'greengo/desktop' '$S' | wc -l) -eq 1 ]"

hook()   { echo "{\"session_id\":\"t1\",$1}" | "$G" hook; }
status() { echo '{"session_id":"t1","context_window":{"used_percentage":42}}' | "$G" status | sed 's/\x1b\[[0-9;]*m//g'; }

echo "Session"
hook '"hook_event_name":"SessionStart"'
check "draws the boater"            "status | head -1 | grep -q '┌───┐'"
check "shows his name"              "status | grep -q 'Greengo'"
check "shows the battery"           "status | grep -q '42%'"
hook '"hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/x/app.ts"}}'
check "works with a lasso"          "status | grep -q '~[◯○]'"
check "names the file"              "status | grep -q 'app.ts'"
hook '"hook_event_name":"SubagentStart"'
check "saddles a horse per subagent" "status | grep -q '♞'"
hook '"hook_event_name":"SubagentStop"'
hook '"hook_event_name":"PostToolUseFailure"'
check "turns red on errors"         "echo '{\"session_id\":\"t1\"}' | '$G' status | tail -1 | grep -q \$'\\x1b\\[31m'"
hook '"hook_event_name":"Stop"'
check "smiles when done"            "status | grep -q '‿\\|ᴗ'"
check "no battery for VS Code"      "! (echo '{\"session_id\":\"t1\"}' | GG_NO_BATTERY=1 '$G' status | grep -q '🔋')"

echo "Commands"
"$G" name Tex >/dev/null;    check "rename"    "status | grep -q 'Tex'"
"$G" hat off >/dev/null;     check "hat off"   "[ \$(status | wc -l) -eq 1 ]"
"$G" hat on >/dev/null
"$G" hide >/dev/null;        check "hide"      "[ -z \"\$(status)\" ]"
"$G" show >/dev/null

echo "Faces"
check "every face is 5 columns wide" "python3 - '$G' <<'PY'
import re, sys, unicodedata
src = open(sys.argv[1], encoding='utf-8').read()
body = src[src.index('face_for() {'):src.index('set_state() {')]
faces = set(re.findall(r'\"([^\"\\s]{3})\"', body))
bad = [f for f in faces if any(unicodedata.east_asian_width(c) in 'WF' or unicodedata.combining(c) for c in f)]
sys.exit(1 if bad or not faces else 0)
PY"

echo "Uninstall"
bash "$HOME/.claude/greengo/uninstall.sh" >/dev/null 2>&1
check "files removed"               "[ ! -e '$HOME/.claude/greengo' ]"
check "hooks removed"               "! grep -q greengo '$S'"
check "old status line restored"    "grep -q 'my-old-statusline.sh' '$S'"
check "other mod folders kept"      "grep -q '\"CLAUDE_CODE_PLUGIN_DIRS\": \"~/my-mods\"' '$S'"

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
