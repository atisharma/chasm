# Chasm - CHAracter State Manager (game client)

Chasm is a ***generative text adventure game*** in a ***world you
specify***. It uses generative artificial intelligence to generate
scenes and characters as you play. Unlike simply role-playing with a
chatbot, important state persists (locations, characters, dialogue
etc.)

**This is the client software that connects to a server.**

Chasm is still being written. It's already pretty great though,
with a good model.


## Features

* [x] specify initial world with a short description
* [x] persistent world / locations
* [x] fuzzy matching names of locations
* [x] continue / save file for game
* [x] persistent items
* [x] character inventory
* [x] take, drop, use items
* [ ] permanently modify items
* [x] per-character event memory
* [x] per-character quests
* [x] NPCs should travel
* [ ] NPCs should interact with items
* [ ] NPCs should interact with plot, follow quests
* [x] persistent global event memory (plot events in vector db)
* [x] per-character dialogue memory (snippets in vector db)
* [x] play as any character
* [ ] command-line parameters to override config
* [ ] world editor for manual world construction
* [x] multiplayer - separate out server & client


## Installing and running

### Running the client

Check your settings in `client.toml` and invoke from inside a terminal, so
```bash
$ chasm
```
will connect to the default server with the character name set in the `client.toml` config (see the example).

```toml
name = "Hero"
world = "default world"
chasm_server = "chasm.run:25566"
loglevel = "info"
```

### Character cards

If you want to override your or any other character's attributes
permanently, create a file `characters/Hero.json` (if your character's
name is Hero) with the contents
```json
{
    "name": "Hero",
    "appearance": "Heroic",
    "gender": "Hero's gender",
    "backstory": "Comes from a long line of heroes; heroic from an early age.",
    "voice": "Heroic",
    "traits": "Heroism",
    "likes": "Being heroic",
    "dislikes": "Not being heroic",
    "motivation": "To be heroic"
}
```
reflecting the desired values. Leave out fields and they'll be automatically generated. The `name` field is ignored (since it's implicit in the filename).


## Interface

- [x] management done by config files
- [x] terminal interface
- [ ] web chat interface, since should be remotely available?
- [ ] map display?


## Problems / bugs

There are still many.
