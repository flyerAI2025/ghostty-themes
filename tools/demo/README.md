# Demo Tooling

These scripts are for maintainers who need to regenerate `demo.gif`.

- End users can ignore this directory.
- Keep the scripts tracked in git so the recording process stays auditable.
- Keep generated frames and temporary recording state out of git.
- `tests/smoke.zsh` is separate from demo recording. It is a lightweight regression check, not a GIF generator.
- The first capture on a machine may trigger macOS screen-recording permission prompts.
- The demo flow uses an isolated recording environment plus a generic `demo % ` prompt so the published GIF does not leak local paths, machine names, or user-specific shell state.

Current maintained demo flow:

1. Launch `ghostty-themes` from a clean shell.
2. Type `git`.
3. Use `↑/↓` to browse GitHub / GitLab light and dark themes.
4. Save one dark theme and one light theme.
5. Skip one theme.
6. Switch between the saved picks.
7. Apply the final theme.

Recommended recording entrypoint:

1. Run `tools/demo/launch-window.zsh`.
   Set `DEMO_SCREEN_ID=<screen-id>` first if you want to pin recording to a specific display.
2. Start frame capture against the returned Ghostty window id.
3. Replay the interaction with `tools/demo/replay-git-save-skip.zsh <window-id>`.
