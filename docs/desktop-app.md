# Greengo in the Claude desktop app

The Code tab in the Claude desktop app doesn't display terminal status lines. Greengo's hooks still run there, so his mood keeps up, but nothing draws him. A small Claude Code mod fills that gap: it shows the full Greengo, with boater, colors and the once-a-second animation, in a band right above the prompt.

```
 ┌───┐
┌[≖_≖]┘~◯ Greengo readin' auth.ts 📜
```

The battery meter is the only thing missing. As in VS Code, only the terminal status line gets the context window size.

## Installing

`./install.sh` sets it up for you:

1. it copies the mod to `~/.claude/greengo/desktop/`
2. it adds that folder to `CLAUDE_CODE_PLUGIN_DIRS` in the `env` block of `~/.claude/settings.json`, keeping any other folders you listed there

Then start a new session in the Code tab. Sessions that were already open don't pick it up.

The mod needs a recent Claude Code (2.1.304 or newer). The desktop app keeps its own copy up to date. If you also run `claude` in a terminal, update that copy with `claude update`.

## How it works

The mod is one hooks module, [`desktop/hooks/register.tsx`](../desktop/hooks/register.tsx):

- When the session starts, it sets a once-a-second timer. Each tick runs `greengo.sh status` for the session with `GG_NO_BATTERY=1`, as the VS Code extension does.
- It splits the output's terminal colors into colored runs and draws them in the band above the prompt, in a monospaced font so the boater sits on his head. The boater's pale terminal straw becomes a saddle brown (`#a8743c`), because the band can't tell a light theme from a dark one and that shade reads on both.
- It redraws only when the output changes, and draws nothing while a survey holds the band.
- It draws only on the `desktop` surface. In a terminal his status line already shows him, and in VS Code the extension does.

So any line or face you add to `greengo.sh` shows up in the desktop app too. `/greengo hide`, `/greengo color …` and `/greengo name …` apply there as well.

## Developing the mod

Work in [`desktop/`](../desktop/), then run `./install.sh` and start a new desktop session to try it.

```bash
claude plugin validate desktop   # reads the mod the way Claude Code will
claude plugin test desktop       # runs desktop/tests/band.test.tsx
```

Claude Code writes the API types to `desktop/.claude-plugin/types/` and a `desktop/tsconfig.json` the first time it loads the mod from that folder. Both are git-ignored.
