import glob
import subprocess


def hermes_add_key_command(chain, file, key_name, is_mnemonic):
    if not is_mnemonic:
        return f"hermes --config config.toml keys add --chain {chain} --key-file {file} --key-name {key_name}"
    else:
        return f"hermes --config config.toml keys add --chain {chain} --mnemonic-file {file} --key-name {key_name}"


keys = glob.glob("keys/*")
if not len(keys):
    print("No keys found in /keys")
    exit(0)

for file in glob.glob("keys/*"):
    file_parts = file.split("/")[-1].split('@')

    if file.endswith(".json"):
        chain = file_parts[0]
        key_name = file_parts[1]
        print(f"Adding key {key_name} for chain {chain}")

        cmd = hermes_add_key_command(chain, file, key_name, False)
        ret = subprocess.run(cmd, shell=True, check=False)
    elif file.endswith(".toml"): # only for namada
        chain = file_parts[0]
        key_name = file_parts[1]
        print(f"Adding key {key_name} for chain {chain}")

        cmd = hermes_add_key_command(chain, file, key_name, False)
        ret = subprocess.run(cmd, shell=True, check=False)
    else: # mnemonic
        chain = file_parts[0]
        key_name = file_parts[1]
        print(f"Adding key {key_name} for chain {chain}")

        cmd = hermes_add_key_command(chain, file, key_name, True)
        ret = subprocess.run(cmd, shell=True, check=False)