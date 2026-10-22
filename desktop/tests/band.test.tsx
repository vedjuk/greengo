import { expect, mock, test } from 'claude-code/testing'

const BAND = {
  plugin: 'greengo',
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: false,
    maxRows: 10,
    bodyColumns: 80,
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const DRAWING =
  '\x1b[38;5;223m\x1b[4m ┌───┐ \x1b[0m\n' +
  '\x1b[32m┌[≖_≖]┘~◯\x1b[0m \x1b[32mGreengo\x1b[0m readin\' app.ts 📜\n'

test('draws what greengo.sh status prints, on desktop only', async ($, on) => {
  const clock = mock.clock(on)
  // Stands for the engine's own drawing, under the plugin.
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const runs: { argv: readonly string[]; init?: { stdin?: string; env?: Record<string, string> } }[] = []
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('session.id', () => ({ value: 't1' }))
  on('process.run', (_, e) => {
    runs.push(e)
    return { value: { exitCode: 0, stdout: DRAWING, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })

  await $.session.start({ cwd: '/', surface: 'desktop', isInteractive: true })
  await clock.advance(1000)

  expect(runs.length).toBe(1)
  expect(runs[0]?.init?.stdin).toBe('{"session_id":"t1"}')
  expect(runs[0]?.init?.env?.GG_NO_BATTERY).toBe('1')

  const ui = await $.ui.mount({ ...BAND, surface: 'desktop' })
  expect((await ui.find({ type: 'Text', text: /┌───┐/ }))?.text).toContain('┌───┐')
  expect((await ui.find({ type: 'Text', text: /readin' app\.ts/ }))?.text).toContain('Greengo')
  await ui.unmount()

  // In the terminal the status line already shows him: the band is left to the engine.
  const term = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await term.find({ type: 'Text', text: /engine/ }))?.text).toBe('engine')
  await term.unmount()
})
