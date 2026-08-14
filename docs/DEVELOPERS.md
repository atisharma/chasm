# Developing chasm

This complements `ARCHITECTURE.md`. Read that first for how the system works.

## Language Split

| Component | Language | Location |
|-----------|----------|----------|
| CLI tool (new, play, validate, list, delete, update) | Python 3 | `chasm` |
| Game bootstrap Q&A | Python 3 | `template/bin/bootstrap` |
| In-game save script | Shell / Python | `template/bin/save` |
| Pi session extensions | TypeScript | `template/.pi/extensions/` |
| Install script | Bash | `install.sh`, `web-install.sh` |

## Working on Extensions (TypeScript)

Extensions in `template/.pi/extensions/` are auto-discovered by pi from the game directory's own `.pi` tree. The template's `settings.json` already points to that directory — **do not hardcode absolute paths**.

Key extension files:
- `chasm-tools.ts` — compact renderers that replace the default pi tool output (fixes a `setToolsExpanded(false)` timing issue)
- `chasm-footer.ts` — reads `WORLD.md` + `WORLD_STATE.md` to render a game-state footer

Extensions hook pi events such as `session_start`, `agent_start`, etc.

### Verifying extension changes

1. Make your change in `template/.pi/extensions/`.
2. Run `chasm new test-world` in a temp directory to instantiate a fresh game.
3. `cd` into the game and start `pi` — confirm extensions load without errors and render as expected.

## Working on the CLI (Python)

The `chasm` binary is static and relocatable. It resolves game locations from
`$XDG_DATA_HOME` (default `~/.local/share/chasm/`), not from its own install
path.

### XDG directories used

| Purpose | Variable | Default |
|---------|----------|---------|
| Data (games, user models.json) | `XDG_DATA_HOME` | `~/.local/share/chasm/` |
| Config | `XDG_CONFIG_HOME` | `~/.config/chasm/` |

`chasm new` creates games under the data directory. Each game is a git repo with the template copied into it.

### Symlink behaviour

On game creation, the game directory symlinks `models.json` to the user-level copy at `${CHASM_DATA}/models.json`. This persists across template updates. Do not make games depend on the template directory directly after creation.

## Working on the Template

The template lives in `template/`. It is copied verbatim by `chasm new`.

- `template/settings.json` — pi config (model, extensions, quiet startup patches)
- `template/bin/bootstrap` — interactive script that writes `WORLD.md`, `WORLD_STATE.md`, and the first place
- `template/memory/` — narrator spec (`AGENTS.md`) and format docs (`CHARACTERS.md`, etc.)

Changes to the template affect only **new** games. For existing installs and
games, use `chasm update` (template + CLI) or `chasm update GAME` / `chasm
update --all` (managed tooling and narrator-spec files only; game content is
never touched).

## Manual Testing (No Automated Suite Yet)

Before submitting changes, verify manually:

1. **Install / dry-run:** `XDG_DATA_HOME=/tmp/chasm-test/share ./install.sh --prefix /tmp/chasm-test` and inspect the result. (The CLI reads `$XDG_DATA_HOME/chasm`, while `install.sh` writes to `$PREFIX/share/chasm`; these coincide only when `PREFIX` is `~/.local` or chosen to match, as here.)
2. **Create a world:** `XDG_DATA_HOME=/tmp/chasm-test/share /tmp/chasm-test/bin/chasm new test-world` — check the symlink target of `models.json`.
3. **Bootstrap a world:** `cd` into the game and run `./template/bin/bootstrap` interactively. Verify `memory/WORLD.md`, `memory/WORLD_STATE.md`, and `memory/places/*.md` are written correctly.
4. **Extension load:** Start `pi` inside the game directory. Confirm the footer renders and tools are compact.

## Coding Conventions

- **TypeScript extensions:** Keep renderers stateless and small. Avoid accumulating DOM state between hooks.
- **Python CLI:** Prefer `pathlib.Path` over string paths. Follow the existing `argparse` pattern.
- **JSON files:** Keep compact (no trailing whitespace, consistent indentation).
- **Shebangs:** `#!/usr/bin/env python3` for Python, `#!/usr/bin/env bash` for Bash.
