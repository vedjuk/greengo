---
name: greengo
description: Customize Greengo, the little green cowboy robot in the status line — rename it, recolor it, hide or show it, or see its stats. Use when the user types /greengo.
argument-hint: "name <name> | color <color> | hat on|off | hide | show | stats"
disable-model-invocation: true
allowed-tools: Bash(~/.claude/greengo/greengo.sh:*), Bash("$HOME/.claude/greengo/greengo.sh":*)
---

Run this with the Bash tool, passing the user's arguments through exactly:

```
~/.claude/greengo/greengo.sh $ARGUMENTS
```

If no arguments were given, run `~/.claude/greengo/greengo.sh stats` instead.

Then reply with the command's output plus one short, playful line in the voice of a cheerful little green cowboy robot (a frontier drawl, "partner", "yeehaw" welcome). Nothing else.
