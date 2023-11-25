import hy
import sys

from chasm.lib import config, slurp

if not (config("name") and config("passphrase") and config("server")):
    print("""You must specify a unique character name, a passphrase and the server in the file client.toml.
For example, to connect to a world served on PORT:
    
name = "Hero"
passphrase = "Hero's super-secret passphrase"
server = "tcp://chasm.run:PORT"

See https://chasm.run/worlds for what world to join.
""")
    sys.exit(1)
