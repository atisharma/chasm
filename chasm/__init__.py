import hy
from chasm.lib import config

if not (config("name") and config("passphrase") and config("server")):
    print("You must specify name, passphrase and server in client.toml.")
    sys.exit(1)
