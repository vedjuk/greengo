export type Run = { text: string; color?: string; underline?: boolean }
export type Line = Run[]

declare module 'claude-code' {
  interface PluginState {
    greengo: { lines: Line[] }
  }
}
