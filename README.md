# Chasm

## A generative interactive fiction text adventure

Chasm is a single-player text adventure game in a world you can specify. It
uses generative artificial intelligence (LLMs) to generate scenes and
characters as you play.

Unlike simply role-playing with a chatbot, important state persists (locations,
characters, dialogue, events and so on) between sessions. Each world is simply
a directory of markdown files: a language model narrates your story through the
[pi coding harness](https://pi.dev) (and inherits its architecture).

Play is single-player, but a world is a git repo: you can distribute it and
someone else can continue it.

## Install

Requires Node.js 18+, npm, git, and Python 3.

**Quick install (one-liner):**
```bash
curl -sSL https://chasm.run/web-install.sh | bash
```

**Or clone manually:**
```bash
git clone https://github.com/atisharma/chasm.git
cd chasm
./install.sh --local
```

If `pi` is not on your PATH, the installer will install it via npm. On a
fresh install it asks whether to reuse your existing pi model config
(`~/.pi/agent/models.json`); answering yes copies it to
`~/.local/share/chasm/models.json` (more generally
`$XDG_DATA_HOME/chasm/models.json`). Each game inherits this file via a
symlink created by `chasm new`.

**When starting** you'll need to configure a model by typing `/login` (unless
you reused your pi config during install).

Chasm requires a model with tool-use support (function calling). Good choices
as of 2026: Kimi K2.5, Mistral Medium 3.5, Sonnet 4.5 via OpenRouter. You can
configure local models via vLLM, for which you'll have to edit
`~/.local/share/chasm/models.json` (more generally
`$XDG_DATA_HOME/chasm/models.json`; see the `pi` [documentation to set up
models](https://pi.dev/docs/latest/providers)). Each game inherits this file
via a symlink created by `chasm new`. Qwen 3.6 27b, Gemma 4 work well.

During play, switch models with **Ctrl+L**.

## Quick Start

```bash
chasm new sunken-quarter
chasm play sunken-quarter
```

Game names must use only letters, digits, hyphens, and underscores (no
spaces). Use kebab-case (`sunken-quarter`) or snake_case
(`sunken_quarter`).

First launch triggers a short Q&A — title, setting, genre, tone, a unique rule,
and starting place. The narrator then drops you into the world.

Resume later: `chasm play sunken-quarter`.

## Updating

```bash
chasm update                 # refresh the installed template + CLI
chasm update sunken-quarter  # refresh tooling files in one game
chasm update --all           # refresh tooling files in every game
chasm update --all --force   # ...overwriting locally-modified tooling files
```

`chasm update` pulls the latest template and CLI from the canonical repo into
`~/.local/share/chasm/` (`$XDG_DATA_HOME/chasm/`; your `models.json` config
there and all games are preserved). `chasm update GAME` refreshes only the managed tooling files in an
existing game (`settings.json`, `bin/`, `.pi/extensions/`, `.gitignore`) and
commits them as `[chasm] Update template files`. Game content — `memory/`,
`APPEND_SYSTEM.md`, sessions, and the `models.json` symlink — is never
touched. Tooling files you have edited locally are skipped with a warning
unless `--force` is given.

## In-Game Commands

Type natural language to act in the world. The narrator interprets your
commands and responds in second-person prose.

| Command | What it does |
|----------|-------------|
| `Ctrl+L` | Switch models mid-session |
| `Ctrl+O` | Expand/collapse tool output |
| `/save` | Force a save of the game state |
| `/sync` | Force the narrator to re-read and persist state (use if the model forgets) |
| `/compact` | Compact the context (use if the model's beginning to forget its instructions, or getting confused) |

## How It Works (Briefly)

A Chasm world is a **git repo** of markdown files. The narrator reads state,
interprets your commands, and writes the story back. Everything is visible and
editable. See `docs/architecture.md` for the full picture.

## Troubleshooting

**Model not configured:** Run `pi /login`, or edit
`~/.local/share/chasm/models.json` (`$XDG_DATA_HOME/chasm/models.json`)
manually — each game inherits it via a symlink.

**First launch shows placeholder text:** Run `chasm play` again; the bootstrap
runs only when `WORLD.md` is uninitialised.

**Permission denied on `chasm`:** Ensure `~/.local/bin` is on your PATH, or use
the full path.

### Disclaimer

There is no good way to moderate the actions and writing of language models.
Chasm could offend you, embarrass you in front of your mother-in law, execute
`rm -rf ~` or even execute your kitten. You must check prompts that other
people provide for such instructions. No guarantees thereof are offered.

## License

MIT. See `LICENSE`.
