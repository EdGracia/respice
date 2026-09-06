# Respice

A stoic companion plugin for [Omarchy](https://omarchy.org) — memento mori
reminders and stoic reflections, right in the bar.

*Respice* (Latin: "look back/behind") — from the reminder Roman generals
were said to have whispered to themselves in triumph: memento mori, respice
post te, hominem te esse memento. "Remember, you are only a man."

## Status

Early scaffold. Currently a bar pill that rotates through a handful of
stoic quotes on a timer and on click.

## Development

Symlink this repo into your Omarchy plugin directory so the shell picks it
up and hot-reloads on save:

```bash
ln -s "$(pwd)" ~/.config/omarchy/plugins/respice
omarchy plugin enable respice
```

Validate the manifest at any point with:

```bash
omarchy plugin validate .
```

Useful commands while iterating:

```bash
omarchy-shell shell rescanPlugins   # force a reload if a change doesn't apply
omarchy restart shell               # full shell restart
```

## License

MIT
