import hy
import sys

from chasm.lib import config, barf

def _berate_config():
    print("""You must specify a unique character name, a passphrase and the server in the file client.toml.
For example, to connect to a world served on PORT:
    
name = "Hero"
passphrase = "Hero's super-secret passphrase"
server = "tcp://chasm.run:PORT"

See https://chasm.run/worlds for what world to join.
""")

try:
    if not (config("name") and config("passphrase") and config("server")):
        _berate_config()
        sys.exit(1)
except FileNotFoundError:
    barf('name = "Player"\npassphrase = "your secret passphrase"\nserver = "https://chasm.run:WORLD_PORT"\n', "client.toml")
    print("""The file client.toml needs to be in the current directory.
I've saved a template you can edit.
""")
    _berate_config()

    sys.exit(1)
