# Ghostty Matrix Power

A Ghostty shader with a Matrix-style rain overlay, typing heat, screen shake, and sparks. The Zsh integration sends cursor color updates to the shader and stores toggle state per terminal.

## Install

Run `./install.sh` to add this project's Ghostty config to the Ghostty configuration file. The installer writes a generated config with absolute paths for the shader and `launch-shell`. Open a new Ghostty window after installation.

The installer derives paths from its own location, so the project can live in a different directory. It updates the generated config on each run. The `install.sh` script adds the initial config loader to Ghostty; no project path needs to be added to the user's `.zshrc`.

## Controls

| Shortcut | Effect |
| --- | --- |
| `Cmd+Shift+P` | Toggle the full Matrix effect |
| `Cmd+Shift+B` | Toggle background rain |
| `Cmd+Shift+I` | Toggle idle animation |
| `Cmd+Shift+S` | Toggle screen shake |
| `Cmd+Shift+K` | Toggle sparks |

Toggle state is saved per terminal under `${XDG_STATE_HOME:-~/.local/state}/matrix-power/`.

## Files

- `config` — Ghostty appearance, shader, and key bindings
- `shaders/matrix-power.glsl` — Matrix Power shader
- `shell/heat.zsh` — typing heat and toggle integration
- `bin/` — terminal effect commands
- `install.sh` — adds the config loader to Ghostty's config
