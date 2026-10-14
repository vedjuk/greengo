// Greengo for VS Code: shows the same Greengo that lives in Claude Code's terminal
// status line, but in VS Code's status bar and in a small panel of his own.
//
// It doesn't duplicate any of his personality. Once a second it asks
// ~/.claude/greengo/greengo.sh to draw him for the most recently active Claude
// session (the hooks keep that up to date, in the chat panel and the terminal alike)
// and turns the terminal colors into VS Code colors.

const vscode = require('vscode');
const cp = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const GG_DIR = path.join(os.homedir(), '.claude', 'greengo');
const SCRIPT = path.join(GG_DIR, 'greengo.sh');
const STATE_DIR = path.join(GG_DIR, 'state');

// ---------- talking to greengo.sh ----------

// The session whose state file changed last is the one Greengo is watching.
function latestSession() {
  try {
    let best = 'default', bestTime = 0;
    for (const f of fs.readdirSync(STATE_DIR)) {
      if (f.includes('.')) continue;                    // skip *.horses and *.tmp
      const t = fs.statSync(path.join(STATE_DIR, f)).mtimeMs;
      if (t > bestTime) { bestTime = t; best = f; }
    }
    return best;
  } catch { return 'default'; }
}

function drawGreengo() {
  return new Promise((resolve) => {
    if (!fs.existsSync(SCRIPT)) return resolve(null);
    const child = cp.execFile('/bin/bash', [SCRIPT, 'status'],
      { env: { ...process.env, GG_NO_BATTERY: '1' }, timeout: 3000 },
      (err, stdout) => resolve(err ? null : stdout));
    child.stdin.on('error', () => {});
    child.stdin.end(JSON.stringify({ session_id: latestSession() }));
  });
}

// ---------- terminal colors → VS Code ----------

const ANSI_VARS = {
  31: 'ansiRed', 32: 'ansiGreen', 33: 'ansiYellow', 34: 'ansiBlue',
  35: 'ansiMagenta', 36: 'ansiCyan', 90: 'ansiBrightBlack', 97: 'ansiBrightWhite',
};
// 223 is the hat's straw; it gets a darker shade on light themes (see the panel's CSS).
const XTERM_256 = { 208: '#ff8700', 213: '#ff87ff', 223: 'var(--gg-straw)' };

// Split one line of terminal output into styled runs of text.
function parseAnsi(line) {
  const runs = [];
  let style = {};
  let last = 0;
  const re = /\x1b\[([0-9;]*)m/g;
  let m;
  const push = (text) => { if (text) runs.push({ text, ...style }); };
  while ((m = re.exec(line))) {
    push(line.slice(last, m.index));
    last = re.lastIndex;
    const codes = m[1] === '' ? [0] : m[1].split(';').map(Number);
    for (let i = 0; i < codes.length; i++) {
      const c = codes[i];
      if (c === 0) style = {};
      else if (c === 1) style = { ...style, bold: true };
      else if (c === 2) style = { ...style, dim: true };
      else if (c === 4) style = { ...style, underline: true };
      else if (c === 38 && codes[i + 1] === 5) { style = { ...style, color: XTERM_256[codes[i + 2]] || null, ansi: null }; i += 2; }
      else if (ANSI_VARS[c]) style = { ...style, ansi: c, color: null };
    }
  }
  push(line.slice(last));
  return runs;
}

const stripAnsi = (s) => s.replace(/\x1b\[[0-9;]*m/g, '');
const escapeHtml = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

function toHtml(output) {
  return output.replace(/\n+$/, '').split('\n').map((line) =>
    parseAnsi(line).map((r) => {
      const css = [];
      if (r.ansi) css.push(`color: var(--vscode-terminal-${ANSI_VARS[r.ansi]})`);
      if (r.color) css.push(`color: ${r.color}`);
      if (r.bold) css.push('font-weight: 600');
      if (r.dim) css.push('opacity: 0.6');
      if (r.underline) css.push('text-decoration: underline; text-underline-offset: 0.12em; text-decoration-thickness: 1px');
      return css.length ? `<span style="${css.join('; ')}">${escapeHtml(r.text)}</span>` : escapeHtml(r.text);
    }).join('')
  ).join('\n');
}

// The compact version: just the face line, as plain text.
function toStatusBar(output, maxLength) {
  const lines = output.replace(/\n+$/, '').split('\n');
  const faceLine = lines[lines.length - 1] || '';
  const isError = faceLine.startsWith('\x1b[31m');
  let text = stripAnsi(faceLine).trim().replace(/\$\(/g, '$​(');   // never let text turn into a codicon
  const chars = Array.from(text);
  if (chars.length > maxLength) text = chars.slice(0, maxLength - 1).join('') + '…';
  return { text, isError };
}

// ---------- the panel ----------

class GreengoPanel {
  constructor() { this.view = null; }

  resolveWebviewView(view) {
    this.view = view;
    view.webview.options = { enableScripts: true };
    view.webview.html = this.page();
    view.onDidDispose(() => { this.view = null; });
  }

  get visible() { return !!(this.view && this.view.visible); }

  show(html) { if (this.view) this.view.webview.postMessage({ html }); }

  page() {
    const size = vscode.workspace.getConfiguration('greengo').get('panelFontSize', 18);
    const nonce = Math.random().toString(36).slice(2);
    return `<!doctype html><html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}';">
<style>
  body { --gg-straw: #ffd7af; }
  body.vscode-light, body.vscode-high-contrast-light { --gg-straw: #9a6b2f; }
  body { margin: 0; padding: 14px 18px; color: var(--vscode-foreground); background: transparent; }
  pre { margin: 0; font-family: var(--vscode-editor-font-family, Menlo, monospace); font-size: ${size}px; line-height: 1.3; white-space: pre; }
  .empty { font-family: var(--vscode-font-family); font-size: 13px; opacity: 0.7; }
</style></head><body>
<pre id="g"><span class="empty">Greengo is saddlin' up… (is the Greengo installer done?)</span></pre>
<script nonce="${nonce}">
  const g = document.getElementById('g');
  window.addEventListener('message', (e) => { g.innerHTML = e.data.html; });
</script></body></html>`;
  }
}

// ---------- wiring it up ----------

function activate(context) {
  const panel = new GreengoPanel();
  context.subscriptions.push(vscode.window.registerWebviewViewProvider('greengo.view', panel));

  const item = vscode.window.createStatusBarItem('greengo.statusBar', vscode.StatusBarAlignment.Right, 1000);
  item.name = 'Greengo';
  item.command = 'greengo.showPanel';
  item.tooltip = 'Greengo, yer cowboy robot. Click to open his panel.';
  context.subscriptions.push(item);

  context.subscriptions.push(
    vscode.commands.registerCommand('greengo.showPanel', () =>
      vscode.commands.executeCommand('greengo.view.focus')),
    vscode.commands.registerCommand('greengo.toggleStatusBar', () => {
      const cfg = vscode.workspace.getConfiguration('greengo');
      cfg.update('statusBar', !cfg.get('statusBar', true), vscode.ConfigurationTarget.Global);
    }),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('greengo.panelFontSize') && panel.view) panel.view.webview.html = panel.page();
    })
  );

  let busy = false;
  const tick = async () => {
    const cfg = vscode.workspace.getConfiguration('greengo');
    const wantBar = cfg.get('statusBar', true);
    if (!wantBar) item.hide();
    if ((!wantBar && !panel.visible) || busy) return;

    busy = true;
    const out = await drawGreengo();
    busy = false;

    if (!out || !out.trim()) {
      item.hide();
      panel.show(fs.existsSync(SCRIPT)
        ? '<span class="empty">Greengo rode off for now. (/greengo show brings him back)</span>'
        : '<span class="empty">Greengo is saddlin\' up… Run install.sh to bring him into town.</span>');
      return;
    }
    if (wantBar) {
      const { text, isError } = toStatusBar(out, cfg.get('statusBarMaxLength', 60));
      item.text = text;
      item.color = new vscode.ThemeColor(isError ? 'terminal.ansiRed' : 'terminal.ansiGreen');
      item.show();
    }
    if (panel.visible) panel.show(toHtml(out));
  };

  const timer = setInterval(tick, 1000);
  context.subscriptions.push({ dispose: () => clearInterval(timer) });
  tick();
}

function deactivate() {}

module.exports = { activate, deactivate, _test: { parseAnsi, toHtml, toStatusBar, stripAnsi } };
