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

Reflections you add are saved to
`~/.local/state/omarchy/respice-reflections.json` and survive a shell
restart or logout. It's a plain JSON array of strings, so you can hand-edit
or delete entries there too — changes to the file are picked up live,
without needing to reopen the panel.

On top of that, Respice periodically pushes one of the quotes as a desktop
notification — a nod to the servant Roman generals were said to have kept
at their side to keep whispering "memento mori" during a triumph. It picks
a random gap (1–5 hours) between reminders, all day, with no
active-hours restriction yet (planned for a future settings UI). A
**Random Reminders** toggle in the panel turns these off entirely; the setting is
persisted and survives a shell restart.

## Project layout

- `manifest.json` — plugin metadata (id `respice`, kind `bar-widget`).
- `BarWidget.qml` — the bar icon and click-to-toggle wiring; also the
  owner of the shared quote list/index and the random-interval reminder
  timer, since it (unlike the panel) is never torn down.
- `Panel.qml` — the popup: the "Add reflection" editor and all the UI,
  reading/mutating quote state on `BarWidget.qml` via `hostWidget`.
- `~/.local/state/omarchy/respice-reflections.json` — where custom
  reflections are stored (not part of this repo; created on first save).
  A plain JSON array of strings — hand-edit or delete entries here if
  you'd rather manage your reflections outside the panel.
- `~/.local/state/omarchy/respice-settings.json` — stores the Random Reminders
  toggle (`{ "reminderEnabled": true }`), created the first time it's
  flipped in the panel.

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
