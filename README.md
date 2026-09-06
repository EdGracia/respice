# Respice

**Pronunciation:** RES-pi-keh (Classical Latin /ˈres.pi.kɛ/)

A stoic companion plugin for [Omarchy](https://omarchy.org) — memento mori
reminders and stoic reflections, right in the bar.

*Respice* (Latin: "look back/behind") — from the reminder Roman generals
were said to have whispered to themselves in triumph: memento mori, respice
post te, hominem te esse memento. "Remember, you are only a man."

## What it does

A 🧔🏼 icon sits in the bar (currently pinned to the right section). Clicking
it drops a panel directly beneath the icon with:

- The current stoic quote.
- **Next reflection** — cycles to the next quote.
- **Add reflection** — opens a text field to write your own (30-word limit,
  enforced as you type). Press Enter or click **Save** to add it to the
  rotation; Escape or **Cancel** discards it.

Reflections you add only live in memory for the current shell session —
nothing is persisted to disk yet, so a shell restart or logout clears them
back to the built-in quotes.

## Project layout

- `manifest.json` — plugin metadata (id `respice`, kind `bar-widget`).
- `BarWidget.qml` — the bar icon; owns nothing but the click-to-toggle
  wiring, forwarding `open`/`close`/`toggle` to the panel.
- `Panel.qml` — the popup: quote state, the "Add reflection" editor, and
  all the UI.

## Development

The Omarchy shell only loads plugins from `~/.config/omarchy/plugins/<id>/`,
and `omarchy plugin validate` (and the shell itself) **refuses a plugin
folder that is a symlink** — a real directory is required. So, until this
repo has a sync script, copy your changes over after each edit:

```bash
rm -rf ~/.config/omarchy/plugins/respice
cp -r ~/Projects/respice ~/.config/omarchy/plugins/respice
omarchy plugin validate ~/.config/omarchy/plugins/respice
omarchy plugin enable respice   # only needed the first time
omarchy restart shell
```

`omarchy restart shell` is only needed for QML logic changes. Bar layout
changes (position, section) hot-reload on save via `~/.config/omarchy/shell.json`.

Useful commands while iterating:

```bash
omarchy bar move respice --section right   # bar placement
omarchy-shell shell rescanPlugins          # force a reload if a change doesn't apply
```

## License

MIT
