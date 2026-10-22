#!/usr/bin/env python3
"""Add or remove Greengo's hooks, status line and desktop mod in ~/.claude/settings.json.

usage: merge_settings.py install|uninstall <settings.json> <gg_dir>
Keeps every other setting and hook untouched and writes a backup first.
"""
import json, os, shutil, sys, time

MARK = "/.claude/greengo/greengo.sh"
EVENTS = ["SessionStart", "UserPromptSubmit", "PreToolUse", "PostToolUseFailure",
          "Notification", "SubagentStart", "SubagentStop", "Stop", "StopFailure",
          "PreCompact", "SessionEnd"]
# The desktop app's sessions load mods from the folders this variable lists.
PLUGIN_DIRS = "CLAUDE_CODE_PLUGIN_DIRS"
DESKTOP_MOD = "~/.claude/greengo/desktop"


def is_greengo(handler):
    return MARK in str(handler.get("command", ""))


def strip_greengo(settings):
    hooks = settings.get("hooks", {})
    for event in list(hooks):
        groups = []
        for group in hooks[event]:
            kept = [h for h in group.get("hooks", []) if not is_greengo(h)]
            if kept:
                group["hooks"] = kept
                groups.append(group)
        if groups:
            hooks[event] = groups
        else:
            del hooks[event]
    if "hooks" in settings and not settings["hooks"]:
        del settings["hooks"]

    env = settings.get("env", {})
    dirs = [d for d in str(env.get(PLUGIN_DIRS, "")).split(os.pathsep) if d and "/.claude/greengo/" not in d]
    if dirs:
        env[PLUGIN_DIRS] = os.pathsep.join(dirs)
    else:
        env.pop(PLUGIN_DIRS, None)
    if "env" in settings and not settings["env"]:
        del settings["env"]


def main():
    mode, path, gg_dir = sys.argv[1], os.path.expanduser(sys.argv[2]), sys.argv[3]
    settings = {}
    if os.path.exists(path):
        with open(path) as f:
            text = f.read().strip()
        settings = json.loads(text) if text else {}
        shutil.copy(path, f"{path}.greengo-backup-{int(time.time())}")

    strip_greengo(settings)
    prev_file = os.path.join(gg_dir, "previous-statusline.json")
    current = settings.get("statusLine")

    if mode == "install":
        if current and MARK not in str(current.get("command", "")):
            with open(prev_file, "w") as f:
                json.dump(current, f, indent=2)
            print("  saved your existing status line; uninstall puts it back")
        settings["statusLine"] = {
            "type": "command",
            "command": '"$HOME/.claude/greengo/greengo.sh" status',
            "refreshInterval": 1,
        }
        handler = {"type": "command", "command": '"$HOME/.claude/greengo/greengo.sh" hook', "async": True}
        hooks = settings.setdefault("hooks", {})
        for event in EVENTS:
            hooks.setdefault(event, []).append({"hooks": [dict(handler)]})
        env = settings.setdefault("env", {})
        env[PLUGIN_DIRS] = os.pathsep.join(filter(None, [env.get(PLUGIN_DIRS), DESKTOP_MOD]))
    else:
        if current and MARK in str(current.get("command", "")):
            del settings["statusLine"]
            if os.path.exists(prev_file):
                with open(prev_file) as f:
                    settings["statusLine"] = json.load(f)
                os.remove(prev_file)
                print("  restored your previous status line")

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    main()
