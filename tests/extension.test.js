// Tests the VS Code extension's rendering without VS Code: a tiny fake of the
// `vscode` module stands in, and the real greengo.sh draws Greengo.
// Run:  node tests/extension.test.js
const assert = require('assert');
const Module = require('module');
const path = require('path');
const fs = require('fs');
const os = require('os');
const cp = require('child_process');

// Install Greengo into a throwaway home folder and start a session.
const home = fs.mkdtempSync(path.join(os.tmpdir(), 'greengo-'));
fs.mkdirSync(path.join(home, '.claude'));
process.env.HOME = home;
const root = path.join(__dirname, '..');
cp.execFileSync('bash', [path.join(root, 'install.sh')], { env: { ...process.env, PATH: '/usr/bin:/bin' }, stdio: 'ignore' });
cp.execFileSync('bash', [path.join(home, '.claude/greengo/greengo.sh'), 'hook'], {
  input: JSON.stringify({ session_id: 's1', hook_event_name: 'Notification', notification_type: 'permission_prompt' }),
});

// The fake VS Code API.
const item = { show() { this.shown = true; }, hide() { this.shown = false; } };
let provider;
const fakeVscode = {
  StatusBarAlignment: { Right: 2 }, ConfigurationTarget: { Global: 1 },
  ThemeColor: class { constructor(id) { this.id = id; } },
  window: {
    createStatusBarItem: () => item,
    registerWebviewViewProvider: (id, p) => { provider = p; return { dispose() {} }; },
  },
  commands: { registerCommand: () => ({ dispose() {} }), executeCommand() {} },
  workspace: {
    getConfiguration: () => ({ get: (k, d) => d, update() {} }),
    onDidChangeConfiguration: () => ({ dispose() {} }),
  },
};
const realLoad = Module._load;
Module._load = (request, ...rest) => (request === 'vscode' ? fakeVscode : realLoad(request, ...rest));

const ext = require(path.join(root, 'vscode/extension.js'));
const { parseAnsi, toStatusBar } = ext._test;

// Pure helpers.
assert.deepStrictEqual(parseAnsi('\x1b[38;5;223m\x1b[4m ┌───┐ \x1b[0m'),
  [{ text: ' ┌───┐ ', color: 'var(--gg-straw)', ansi: null, underline: true }]);
const trimmed = toStatusBar('\x1b[31m [×_×]\x1b[0m Greengo ' + 'x'.repeat(80), 30);
assert.strictEqual(Array.from(trimmed.text).length, 30);
assert.ok(trimmed.isError);
assert.ok(!toStatusBar('$(zap) sneaky', 60).text.startsWith('$('), 'codicon syntax is defused');

// The whole extension, ticking for real.
const posted = [];
const ctx = { subscriptions: [] };
ext.activate(ctx);
provider.resolveWebviewView({
  visible: true, onDidDispose() {},
  webview: { options: {}, set html(h) {}, postMessage: (m) => posted.push(m.html) },
});

setTimeout(() => {
  try {
    assert.ok(item.shown, 'status bar item is shown');
    assert.match(item.text, /Greengo/);
    assert.doesNotMatch(item.text, /🔋/, 'no battery in VS Code');
    const html = posted[posted.length - 1] || '';
    assert.match(html, /┌───┐/, 'panel shows the boater');
    assert.match(html, /text-decoration: underline/, 'brim is underlined');
    assert.match(html, /var\(--vscode-terminal-ansiGreen\)/, 'uses theme colors');
    console.log('✓ extension renders Greengo in the status bar and the panel');
  } finally {
    ctx.subscriptions.forEach((s) => s.dispose && s.dispose());
    fs.rmSync(home, { recursive: true, force: true });
  }
}, 2500);
