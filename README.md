Incremental :normal
====

Experiment with preview of `:normal` commands. Also probably the most insane multi-cursor implementation for nvim.

To activate, use `:[RANGE]norma ` to place a cursor at the beginning of every line in `[RANGE]`. (As a safe guard, it only activates on this spelling, not `:normal` nor `:norm`) Then type normal-code commands completely _as normal_.

Demonstrates:

- Abusing `<Expr>` and timers to execute commands in command-line mode.
- Abusing `g:Nvim_color_cmdline` and timers to trigger code on cmdline change
- Using `redraw!` to display a temporary buffer state
- Some crashes and weird behavior that needs investigation



