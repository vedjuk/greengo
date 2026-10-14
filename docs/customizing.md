# Customizing Greengo

## The quick stuff

These commands work in Claude Code (as `/greengo …`) or in any terminal (as `~/.claude/greengo/greengo.sh …`):

| Command | Effect |
|---|---|
| `name Tex` | Renames him |
| `color cyan` | green (default), cyan, yellow, red, blue, magenta, white, gray, orange, pink |
| `hat off` / `hat on` | Takes the boater off, which makes him one line tall |
| `hide` / `show` | Hides him everywhere, or brings him back |
| `stats` | Shows rides together and chores wrangled |

Settings are stored in `~/.claude/greengo/config`.

## Editing his personality

Everything else lives in one file, `~/.claude/greengo/greengo.sh`. Edit it with any editor (or ask Claude to). Changes show up within a second, in the terminal and in VS Code, with no restart needed.

> If you cloned the repo, edit `greengo.sh` in the repo and run `./install.sh` again to copy it over, so your changes are kept with the project.

### Add a line

Find the event in `do_hook` and add another quoted string to its `pick` list:

```bash
    Stop)
      set_state happy "$(pick \
        "yeehaw! job's done ✅" \
        "that's a wrap, partner ✅" \
        "this here's my new favorite line 🤠")" ;;
```

For lines about a file, use `${F:-fallback}`, which becomes the file's name:

```bash
          set_state work "$(pick "patchin' up ${F:-the code} 🔨" "lassoin' ${F:-the code} 🪢")" ;;
```

Tips:

- Keep lines short, around 40 characters, so they fit beside the face.
- One emoji at the end keeps the look consistent.
- Apostrophes are fine inside double quotes. Avoid the `|` character, since it separates fields in the state file.

### Add a face

Faces live in `face_for()`, one list per mood:

```bash
    work)   pick "•_•" "≖_≖" "ò_ó" "-_•" "¬_¬" "•ᴗ•" ;;
```

Each face is exactly 3 characters (the brackets are added for you). Use only **single-width** characters: no emoji, no CJK, no combining accents. Otherwise the hat slides off-center. Characters that work well:

| Eyes | Mouths |
|---|---|
| `•` `-` `¬` `≖` `ò` `ó` `^` `°` `×` `=` `´` `` ` `` `≧` `≦` | `_` `ᴗ` `‿` `-` `o` |

`bash tests/smoke.sh` checks that every face is single-width.

Listing a face twice makes it twice as likely. That's how stone cold `¬_¬` wins most standoffs in the `wait` mood.

Idle faces rotate on a timer instead. They're in the `*)` branch near the end of `do_status`, with a separate list for late at night.

### Change the timings

All in `do_status`:

| What | Where | Default |
|---|---|---|
| Fall asleep | `[ "$AGE" -gt 90 ]` | 90 seconds of quiet |
| Settle down after happy or blush | `[ "$AGE" -gt 20 ]` | 20 seconds |
| Calm down after an error | `[ "$AGE" -gt 30 ]` | 30 seconds |
| New idle face | `NOW / 30` | every 30 seconds |
| New idle line | `NOW / 20` | every 20 seconds |
| Night time | `[ "$HOUR" -ge 23 ] \|\| [ "$HOUR" -lt 5 ]` | 11pm to 5am |

### Change the hat

The boater is the line printed under `# The boater:` in `do_status`. It's `┌───┐` with the terminal's underline style across all 7 columns, which draws the brim. Any 7-column hat works, as long as the crown sits in columns 2 to 6, above his head.

## Using a different folder

Greengo keeps his files in `~/.claude/greengo`. Set `GG_DIR` to use another folder, for example while testing changes:

```bash
echo '{"session_id":"test"}' | GG_DIR=/tmp/greengo-test ./greengo.sh status
```
