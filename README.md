<div align="center">

# ghostty-themes

**Interactive theme selector for [Ghostty](https://ghostty.org) with live preview, saved picks, and skips.**

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue?logo=apple&logoColor=white)](#requirements)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Ghostty](https://img.shields.io/badge/Ghostty-1.0%2B-blueviolet)](https://ghostty.org)
[![fzf 0.44+](https://img.shields.io/badge/fzf-0.44%2B-orange)](https://github.com/junegunn/fzf)

**English** | [简体中文](README.zh-CN.md)

[Features](#features) · [Install](#install) · [Usage](#usage) · [How it works](#how-it-works)

</div>

---

<p align="center">
  <img src="demo.gif" alt="ghostty-themes demo" width="800">
  <br>
  <sub>Real interaction capture: type <code>git</code>, browse with <code>↑/↓</code>, save one dark and one light theme, skip one theme, switch between the saved picks, then apply.</sub>
</p>

## Features

- **Live preview** — theme applies to your terminal instantly as you navigate
- **Save lane** — Ctrl-F to save; saved themes stay pinned at the top
- **Skip lane** — Ctrl-D to skip; skipped themes sink to the bottom with a strike-through marker
- **Fast triage** — after Save or Skip, focus advances to the next unmarked theme
- **Code preview panel** — syntax-highlighted Zig, larger 16-color palette chips, text styles, and focus chips for selection / cursor colors — tuned for real terminal use while staying close to [`ghostty +list-themes`](https://github.com/ghostty-org/ghostty/blob/main/src/cli/list_themes.zig)
- **Cancel-safe** — Esc / Ctrl-C restores your original theme
- **System appearance auto-switch** — once your saved light and dark themes both have usage history, confirming a saved theme automatically writes Ghostty's native `light:...,dark:...` pair; `--apply-auto` remains available as a manual refresh
- **Single file** — one script, no config, no build step

## Requirements

- **macOS 13+** (Ventura or later)
- [Ghostty](https://ghostty.org) 1.0+
- [fzf](https://github.com/junegunn/fzf) 0.44+

```bash
brew install fzf    # if you don't have fzf yet
```

## Install

**Quick** (single file, no git):

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/flyerAI2025/ghostty-themes/main/ghostty-themes \
  -o ~/.local/bin/ghostty-themes && chmod +x ~/.local/bin/ghostty-themes
```

**Or clone** (update later via `git pull`):

```bash
git clone https://github.com/flyerAI2025/ghostty-themes.git
chmod +x ghostty-themes/ghostty-themes
mkdir -p ~/.local/bin
ln -sf "$(cd ghostty-themes && pwd)/ghostty-themes" ~/.local/bin/ghostty-themes
```

> Make sure `~/.local/bin` is in your `PATH`. If not, add `export PATH="$HOME/.local/bin:$PATH"` to your `~/.zshrc` and restart your terminal.

## Usage

```bash
ghostty-themes
```

| Key | Action |
|-----|--------|
| `↑` `↓` | Browse themes — **applied in real-time** |
| Type | Fuzzy search / filter |
| `Ctrl-F` | Save / unsave current theme |
| `Ctrl-D` | Skip / unskip current theme |
| `Enter` | Confirm selection |
| `Esc` / `Ctrl-C` | Cancel and restore original theme |

Saved themes appear at the top of the list. Skipped themes stay at the bottom and are shown with a strike-through marker. After Save or Skip, focus stays in the browse lane and advances to the next unmarked theme.

### CLI

```bash
ghostty-themes --apply "Catppuccin Frappe"   # apply a theme directly
ghostty-themes --apply-auto                  # write Ghostty's native light/dark auto pair
ghostty-themes --preview "Dracula"           # render preview (used by fzf)
ghostty-themes --list-saved                  # list saved themes
ghostty-themes --save "Dracula"              # save a theme
ghostty-themes --unsave "Dracula"            # remove from saved
ghostty-themes --list-skipped                # list skipped themes
ghostty-themes --skip "Dracula"              # skip a theme
ghostty-themes --unskip "Dracula"            # remove from skipped
ghostty-themes --help
```

Legacy aliases `--list-fav`, `--add-fav`, and `--rm-fav` still work.

### System Auto Theme

Once your saved themes include both a used light theme and a used dark theme, confirming a saved theme with `Enter` or `--apply` automatically writes Ghostty's native `theme = light:...,dark:...` config using:

- the most-used saved light theme
- the most-used saved dark theme

Usage counts are recorded only when a theme is explicitly kept with `Enter` or `--apply`. Live preview while browsing does not count. Unsaved themes remain explicit manual overrides. `--apply-auto` is still available if you want to force a refresh immediately. If you don't yet have both a saved light theme and a saved dark theme with usage history, the auto-switch logic exits without changing your config.

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `GHOSTTY_CONFIG` | *(auto-detected)* | Override Ghostty config file path |
| `GHOSTTY_THEMES_UI_MODE` | `auto` | Picker layout mode: `auto`, `fullscreen`, or manual-fallback `panel` |
| `GHOSTTY_THEMES_RELOAD_MODE` | `auto` | Reload strategy: `auto`, `script`, or `shortcut` |

Saved themes are stored in `~/Library/Application Support/com.mitchellh.ghostty/theme-favorites` (plain text, sorted, one theme name per line).
Skipped themes are stored in `~/Library/Application Support/com.mitchellh.ghostty/theme-skipped` (plain text, sorted, one theme name per line).
Theme usage counts are stored in `~/Library/Application Support/com.mitchellh.ghostty/theme-usage` (plain text, one `theme<TAB>count` entry per line).

`auto` keeps the stable fullscreen layout. `panel` remains available as a manual fallback for terminals that render fullscreen TUIs poorly.
`auto` reload mode prefers Ghostty's AppleScript `reload_config` action and falls back to the `⌘⇧,` shortcut for older setups.

## How it works

```
ghostty-themes
      │
      ▼
ghostty +list-themes ──▶ fzf ──▶ select theme
                          │          │
              --preview ──┘          │
              (render code sample    ▼
               with theme colors)  --apply
                                     │
                              ┌──────┴──────┐
                              │ update       │
                              │ config file  │
                              │ + reload     │
                              │ (AppleScript │
                              │  first)      │
                              └─────────────┘
```

1. Lists all themes via `ghostty +list-themes`, then splits them into Saved, Browse, and Skipped lanes
2. Pipes into fzf with `--preview` rendering the palette using ANSI 24-bit true color — same content and [color mapping](https://github.com/ghostty-org/ghostty/blob/main/src/cli/list_themes.zig) as Ghostty's built-in preview
3. On each focus change, updates `theme = ...` in your config and reloads Ghostty via AppleScript `reload_config` (with `⌘⇧,` fallback in `auto` mode)
4. Ctrl-F saves and Ctrl-D skips; both persist instantly, reorder the list, and keep focus on the next unmarked theme
5. Esc / Ctrl-C restores the original theme; Enter keeps the selection and records one usage for the final theme
6. Once both saved appearances have usage history, confirming a saved theme automatically switches config to Ghostty's native `light:...,dark:...` pair using the most-used saved light/dark themes
7. `--apply-auto` can force that same refresh on demand

## Troubleshooting

**`fzf not found`** — Install: `brew install fzf`.

**Themes don't apply in real-time** — Ghostty 1.3+ works best because the script can call its AppleScript `reload_config` action directly. On older setups, try `GHOSTTY_THEMES_RELOAD_MODE=shortcut ghostty-themes`.

**System auto-switch hasn't kicked in yet** — This is expected until you have both:

- a saved light theme that you've explicitly applied before
- a saved dark theme that you've explicitly applied before

**Preview looks grayscale** — `ghostty-themes` intentionally bypasses global `NO_COLOR` settings so palette chips and syntax colors remain visible. If you've exported `NO_COLOR=1`, that's expected: the picker still renders colors on purpose.

**Preview shows "Theme not found"** — Run inside a Ghostty terminal so `GHOSTTY_RESOURCES_DIR` is set automatically. Alternatively, check that Ghostty.app is in `/Applications/`.

## Related

This tool addresses several long-standing requests in the Ghostty community:

- [Discussion #8145](https://github.com/ghostty-org/ghostty/discussions/8145) — "Write selected theme from +list-themes to disk"
- [Discussion #7221](https://github.com/ghostty-org/ghostty/discussions/7221) — "Action for switching themes"
- [Discussion #4261](https://github.com/ghostty-org/ghostty/discussions/4261) — "Select theme UI"

## Uninstall

```bash
rm ~/.local/bin/ghostty-themes          # remove symlink
rm -rf <directory-where-you-cloned>     # e.g. rm -rf ~/ghostty-themes
```

To also remove saved preferences and usage data:

```bash
rm -f ~/Library/Application\ Support/com.mitchellh.ghostty/theme-favorites \
      ~/Library/Application\ Support/com.mitchellh.ghostty/theme-skipped \
      ~/Library/Application\ Support/com.mitchellh.ghostty/theme-usage
```

## Contributing

Issues and PRs welcome. This project targets macOS only.

Maintainer-only helpers for re-recording `demo.gif` live in [`tools/demo`](tools/demo).

Smoke test before publishing:

```bash
./tests/smoke.zsh
```

`tests/smoke.zsh` is a lightweight functional regression check for list grouping, save / skip focus behavior, config writes, and preview ANSI output. It does not generate `demo.gif`; the demo is recorded separately from a real Ghostty GUI session.
End users do not need either `tools/demo` or `tests/smoke.zsh` for normal daily use of `ghostty-themes`.

## License

[MIT](LICENSE)
