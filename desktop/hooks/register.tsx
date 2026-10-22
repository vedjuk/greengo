import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import type { Line, Run } from '../types'

// Greengo for the Claude desktop app, whose Code tab draws no terminal status line.
// Once a second this runs greengo.sh status for the session, like the VS Code
// extension does, and draws its colored output in the band above the prompt.
// The terminal and VS Code already have their own Greengo, so it draws on desktop only.

// Greengo's drawing, as greengo.sh status printed it last, split into colored runs.
const lines = atom({ plugin: 'greengo', key: 'lines' } as const, [] as Line[])

const ANSI: Record<number, string> = {
  31: '#e5534b', 32: '#57ab5a', 33: '#c69026', 34: '#539bf5',
  35: '#b083f0', 36: '#39c5cf', 90: '#8b949e', 97: '#f0f0f0',
}

// xterm 256-color index to hex (the boater's straw is 223).
function xterm(n: number): string | undefined {
  if (n < 16) return ANSI[n + 30] ?? ANSI[n - 8 + 90]
  const hex = (v: number) => v.toString(16).padStart(2, '0')
  if (n >= 232) { const g = 8 + (n - 232) * 10; return `#${hex(g)}${hex(g)}${hex(g)}` }
  const c = n - 16, step = (v: number) => (v === 0 ? 0 : 55 + v * 40)
  return `#${hex(step(Math.floor(c / 36)))}${hex(step(Math.floor(c / 6) % 6))}${hex(step(c % 6))}`
}

function parse(out: string): Line[] {
  return out.replace(/\n+$/, '').split('\n').map(raw => {
    const runs: Run[] = []
    let color: string | undefined, underline = false, last = 0
    const re = /\x1b\[([0-9;]*)m/g
    let m: RegExpExecArray | null
    const push = (text: string) => { if (text) runs.push({ text, color, underline }) }
    while ((m = re.exec(raw))) {
      push(raw.slice(last, m.index))
      last = re.lastIndex
      const codes = (m[1] || '0').split(';').map(Number)
      for (let i = 0; i < codes.length; i++) {
        const c = codes[i] ?? 0
        if (c === 0) { color = undefined; underline = false }
        else if (c === 4) underline = true
        else if (c === 38 && codes[i + 1] === 5) { color = xterm(codes[i + 2] ?? 0); i += 2 }
        else if (ANSI[c]) color = ANSI[c]
      }
    }
    push(raw.slice(last))
    return runs
  })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    const stdin = JSON.stringify({ session_id: await $.session.id() })
    let previous = ''

    $.clock.every(1000, async () => {
      try {
        const { stdout } = await $.process.run(
          ['/bin/bash', '-c', 'exec "$HOME/.claude/greengo/greengo.sh" status'],
          { stdin, env: { GG_NO_BATTERY: '1' }, timeoutMs: 5000 },
        )
        if (stdout === previous) return
        previous = stdout
        await update($, lines, () => parse(stdout))
      } catch {
        // Greengo's not installed, or he's slow this second: try again on the next tick.
      }
    })

    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.surface !== 'desktop') return next(e)
    const drawn = await read($, lines)
    if (e.props.hasSurvey || drawn.length === 0 || drawn.every(l => l.length === 0)) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {drawn.map((line, i) => (
          <Text key={`l${i}`} mono>
            {line.map((r, j) => (
              <Text key={`r${j}`} color={r.color} underline={r.underline}>{r.text}</Text>
            ))}
          </Text>
        ))}
      </Box>
    )
  })
}
