# Contributing to Greengo

Howdy, partner, and thanks for riding along! New lines, new faces, bug fixes and ideas are all welcome.

## Easy ways to help

- **New lines.** Got a Western nod or a cowpoke coding pun? Add it to the right mood in `greengo.sh`. See [Customizing](docs/customizing.md#add-a-line).
- **New faces.** Keep them single-width and 3 characters between the brackets. See [Customizing](docs/customizing.md#add-a-face).
- **Bug reports.** Use the [bug report template](https://github.com/vedjuk/greengo/issues/new/choose) and include your terminal, macOS and Claude Code versions.

## Line-writing guidelines

- Keep lines short (about 40 characters) with one emoji at the end.
- Movie references are short nods, not long quotes. A few words that make a fan smile are perfect.
- Good-natured only: no jokes at the expense of real people, groups or cultures.
- Greengo's voice: a laconic, slightly weathered cowboy. Drop the g's ("ridin'"), say "partner", stay friendly.

## Project layout

```
greengo.sh            Greengo himself: hooks, drawing, commands (bash 3.2)
install.sh            Installs into ~/.claude and VS Code
uninstall.sh          Removes everything and restores your old status line
merge_settings.py     Adds or removes Greengo's entries in ~/.claude/settings.json
skill/SKILL.md        The /greengo command
vscode/               The VS Code extension (plain JS, no dependencies)
desktop/              The Claude desktop app mod (a Claude Code hooks module)
greengo.vsix          The built extension that install.sh installs
tests/                Smoke test and extension test
docs/                 Documentation
```

## Development

Work in the repo, then run `./install.sh` to try your changes in Claude Code.

Before opening a pull request:

```bash
bash tests/smoke.sh            # installs into a throwaway home, plays a session, uninstalls
node tests/extension.test.js   # renders Greengo through the extension with a fake VS Code
claude plugin test desktop     # draws Greengo through the desktop mod (if you changed it)
```

The first two also run in CI on macOS and Ubuntu. See [Claude desktop app](docs/desktop-app.md#developing-the-mod) for the mod.

A few rules keep Greengo running everywhere:

- **bash 3.2 only.** That's what macOS ships. No associative arrays, no `${var,,}`, no `mapfile`.
- **No extra dependencies.** No `jq`, no Node for the core. Greengo must run on a stock Mac.
- **Fast.** The status line runs every second. Keep each run to a few milliseconds.
- **Quiet hooks.** Hooks must print nothing, so nothing lands in Claude's context.
- **If you change the extension,** rebuild the `.vsix` with `cd vscode && npm run package` and commit it.

## Pull requests

1. Fork the repo and create a branch.
2. Make your change, and update the docs if behavior changes.
3. Add a line to the `Unreleased` section of [CHANGELOG.md](CHANGELOG.md).
4. Run the tests and open the pull request.

Yeehaw, and thanks! 🤠
