# Troubleshooting

## Greengo doesn't appear in the terminal

1. **Start a new session.** Greengo only shows up in sessions started after installing.
2. **Trust the folder.** Claude Code runs status lines only in folders you've trusted. If it asked about trusting the folder and you said no, restart `claude` there and accept.
3. **Update Claude Code.** Run `claude --version`, then `claude update`. The once-a-second refresh needs a recent version.
4. **Check that he can draw:**
   ```bash
   echo '{"session_id":"test"}' | ~/.claude/greengo/greengo.sh status
   ```
   You should see the boater and his face in color. If you see nothing, he may be hidden: run `~/.claude/greengo/greengo.sh show`.
5. **Check the settings.** `~/.claude/settings.json` should have a `statusLine` whose command mentions `greengo.sh`. Running `./install.sh` again fixes it.
6. **Ask your admin.** If your organization manages Claude Code settings with `allowManagedHooksOnly`, personal hooks and status lines are switched off.

## He appears, but never changes mood

His hooks aren't running. In Claude Code, run `/hooks`: you should see Greengo's hooks under your user settings. If they're missing, run `./install.sh` again. If `disableAllHooks` is set to `true` in your settings, hooks (and Greengo) are off.

## The hat looks off

- **Crown not centered:** a face with a double-width character pushes the head sideways. Check any faces you added (see [Customizing](customizing.md#add-a-face)).
- **Brim doesn't meet the crown:** where the underline sits depends on your terminal font. Try another font, or edit the hat line in `do_status`.
- **Want it gone:** `/greengo hat off`.

## VS Code: no Greengo in the status bar or panel

1. **Reload VS Code** after installing: `Cmd+Shift+P` → **Developer: Reload Window**.
2. **Check the extension is installed:** look for "Greengo" in the Extensions view. If it's missing, install `~/.claude/greengo/greengo.vsix` by hand (Extensions view → `…` → **Install from VSIX…**).
3. **Status bar turned off?** Run **Greengo: Toggle status bar**.
4. **Panel says he rode off:** he's hidden. Run `/greengo show`.
5. **Panel says he's saddlin' up:** Greengo isn't installed in `~/.claude/greengo`. Run `./install.sh`.

## VS Code shows a different session than the one I'm in

The extension follows the session that changed most recently. If two sessions are busy at the same time, he switches to whichever one acted last.

## Claude desktop app: no Greengo above the prompt

1. **Start a new Code session.** The mod loads when a session starts, so sessions already open don't have it.
2. **Check the settings.** `~/.claude/settings.json` should have `"CLAUDE_CODE_PLUGIN_DIRS"` under `env`, listing `~/.claude/greengo/desktop`. Running `./install.sh` again fixes it.
3. **Check that he can draw:** run the `greengo.sh status` command from the top of this page. If it prints nothing, run `/greengo show`.
4. **Check the mod:** `claude plugin validate ~/.claude/greengo/desktop` should pass. It needs Claude Code 2.1.304 or newer; run `claude update` if your `claude` is older.

## The installer asks for python3

The installer uses python3 to edit your settings safely. On macOS, run `xcode-select --install`, then run `./install.sh` again. Greengo himself only needs bash.

## Getting rid of him

```bash
~/.claude/greengo/uninstall.sh
```

Your previous status line comes back, and backups of your settings stay next to `~/.claude/settings.json`.

Still stuck? [Open an issue](https://github.com/vedjuk/greengo/issues/new/choose) and include what `greengo.sh status` prints.
