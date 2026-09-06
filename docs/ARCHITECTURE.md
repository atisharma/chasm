# Chasm Architecture

## How It Works

A Chasm world is just a git repo of markdown files. The narrator reads state,
interprets your commands, and writes the story back:

| File | What it holds |
|------|---------------|
| `memory/WORLD.md` | Setting, genre, prose style, rules |
| `memory/WORLD_STATE.md` | Time, weather, player pointer, quests |
| `memory/places/*.md` | Locations with exits and sensory detail |
| `memory/characters/*.md` | NPCs with motives, memories, inventory |
| `memory/items/*.md` | Portable objects with usage and provenance |
| `memory/events/*.md` | Append-only log of what happened |

Everything is visible. Everything is editable. Save in-world with the `save` command.

The narrator loads `memory/AGENTS.md` at session start — a spec defining narrative
voice, state-mutation rules, and the amnesia bootstrap. `memory/PRINCIPLES.md` is
injected beside it: the game-design principles that bind the narrator as referee
and author.

## Design a World

`chasm new` copies the template. To design a world manually, write
`memory/WORLD.md` — the design document — then create starting places and
characters. The rest emerges through play.

Key format specs live in the template itself:

- `memory/CHARACTERS.md` — character frontmatter and archetypes
- `memory/PLACES.md` — place format, coordinates, exits
- `memory/ITEMS.md` — item types and state transitions
- `memory/EVENTS.md` — classification and compaction strategy
- `memory/QUESTS.md` — quest stages and status tracking

A world workspace is self-contained. Distribute it as a git repository. Players
need only `pi` and the world files.

## Coordinates

Coordinates indicate location, not exact position. Multiple places may share `(x, y)`,
such as rooms within a building. The narrator disambiguates coordinate collisions
by name and narrative context.

## System Structure

```
chasm/                          # This repository (the system)
├── chasm                       # CLI — new, play, list
├── install.sh                  # System installer
├── template/                   # Skeleton game workspace
│   ├── settings.json           # Pi config (model, extensions)
│   ├── extensions/             # chasm-ui.ts (compact tool output)
│   ├── bin/                    # save script + bootstrap Q&A
│   └── memory/                 # Narrator spec + format docs
└── docs/
    └── architecture.md         # This file
```

Each instantiated game is:

```
~/.local/share/chasm/games/my-world/
├── settings.json
├── extensions/
├── bin/
└── memory/
    ├── WORLD.md
    ├── WORLD_STATE.md
    ├── places/
    ├── characters/
    ├── items/
    └── events/
```
