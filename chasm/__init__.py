import hy
import sys

from chasm.lib import config, slurp

if not (config("name") and config("passphrase") and config("server")):
    print("""You must specify a unique name, a passphrase and the server in the file client.toml.
For example:
    
name = "Hero"
passphrase = "Hero's super-secret passphrase"
server = "tcp://chasm.run:25566"
""")
    sys.exit(1)
