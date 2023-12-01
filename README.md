# Chasm - CHAracter State Manager (game client)

Chasm is a ***generative text adventure game*** in a ***world you
specify***. It uses generative artificial intelligence to generate
scenes and characters as you play. Unlike simply role-playing with a
chatbot, important state persists (locations, characters, dialogue
etc.)

See the [example gameplay](example-gameplay.md) for what a new game can be like.

**This is the client software that connects to a server.**
To play, you need to connect to [a server](https://chasm.run/worlds).

Chasm is still being written. It's already pretty great though,
with a good model.


## Features

* [x] specify initial world with a short description
* [x] persistent world / locations
* [x] fuzzy matching names of locations
* [x] continue / save file for game
* [x] persistent items
* [x] character inventory
* [x] per-character event memory
* [x] per-character quests
* [x] take, drop, use items
* [ ] permanently modify items
* [ ] natural item interaction
* [ ] natural item spawning from narrative
* [ ] NPCs should interact with items
* [ ] NPCs should interact with plot, follow quests
* [x] NPCs should travel
* [x] persistent global event memory (plot events in vector db)
* [x] per-character dialogue memory (snippets in vector db)
* [x] play as any character
* [x] world editor / admin repl for manual world construction
* [x] multiplayer - separate async server with many clients
* [x] player authentication


## Installing and running

### Installing

There are a lot of dependencies so it's recommended you install
everything in a virtual environment.
To install using pip:
```bash
$ <activate your venv>
$ pip3 install -U git+https://github.com/atisharma/chasm
# edit the client.toml file (see below), for example using nano
$ nano client.toml
$ chasm
```

You may want to consider using pyenv for complete control over your python version.


### Running the client

Check your settings in `client.toml`, activate your venv and invoke chasm from inside your terminal, so
```bash
$ chasm
```
will connect to the default server with the character name set in the `client.toml` config (see the example). You'll need to specify a passphrase which will be the key for your character.

```toml
name = "Hero"
passphrase = "sup3r-secr3t un1que pa55phrase"
# connect to a world on a specific port on the server
chasm_server = "tcp://chasm.run:PORT"
loglevel = "info"
```
where `PORT` is the port number of your [world](https://chasm.run/worlds).

You'll need to run it inside a terminal that can handle escape characters (colour etc). Any linux terminal should work - I'm not sure about Windows.

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
