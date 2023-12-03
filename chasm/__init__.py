import hy
import sys

from chasm.lib import config, barf

default_config = """name = "Hero"
passphrase = "Hero's super-secret passphrase"
server = "tcp://chasm.run:PORT"
"""

def _berate_config():
    print("You must specify a unique character name, a passphrase and the server in the file client.toml.\nFor example, to connect to a world served on PORT:\n")
    print(default_config)
    print("See https://chasm.run/worlds for what world to join.")

try:
    if not (config("name") and config("passphrase") and config("server")):
        _berate_config()
        sys.exit(1)
except FileNotFoundError:
    barf(default_config, "client.toml")
    print("""The file client.toml needs to be in the current directory.
I've saved a template client.toml you can edit.
""")
    _berate_config()

    sys.exit(1)
