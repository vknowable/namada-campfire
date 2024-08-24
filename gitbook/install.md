# Run a Node on Campfire

**Ready to join [Campfire](https://testnet.luminara.icu), our community-run Namada testnet?** 🏕️  

**If you're looking for instructions on running a node using Docker, they can be found [here](./install-docker.md).**
**Otherwise, if you're using the binaries straight from the command line, continue with the steps below:**  

*Note: you can view the general docs for Namada [here](https://docs.namada.net).*  

If you've previously run a node on the `shielded-expedition`, the process for running on Campfire is very similar -- with a couple minor differences for changing the configs-server location and manually downloading the wasm files.

### 1. Install Namada
1. Check the Campfire [landing page](https://testnet.luminara.icu) to see which version of Namada you will need.
2. Install [Namada](https://github.com/anoma/namada/releases) according to the [instructions](https://docs.namada.net/introduction/install) in the docs. You can either download the pre-built binaries from the GitHub [releases](https://github.com/anoma/namada/releases) page, or clone the repo and build from source.  

There are also Docker images available [here](https://hub.docker.com/r/spork666/namada) and [here](https://github.com/anoma/namada/pkgs/container/namada). The instructions for running a node using Docker are [here](./install-docker.md).
3. Verify your installation with `namada --version`.

### 2. Initialize your node (`join-network`)
1. Check the Campfire [landing page](https://testnet.luminara.icu); you will need the current chain-id.
2. First, set the following env variable in your terminal. This will instruct the `join-network` command to look on the Campfire server when downloading the genesis files: 
```bash copy
export NAMADA_NETWORK_CONFIGS_SERVER="https://testnet.luminara.icu/configs"
```
3. Next, fetch the genesis files:  
*Note: the flag `--dont-prefetch-wasm` is no longer needed post v0.43.0; instead you must provide the directory where the wasm files will be stored*
```bash copy
namadac utils join-network --chain-id $CHAIN_ID --wasm-dir $HOME/.local/share/namada/$CHAIN_ID/wasm
```

### 3. Add `persistent_peers`
Find the persistent peer address on the [landing page](https://testnet.luminara.icu) and add it to your node's config file:  
*Note: below is an example value; yours will be slightly different*
```bash copy
# in file ~/.local/share/namada/$CHAIN_ID/config.toml
persistent_peers = "tcp://af427e348cd45dd7308be4ea58f1492098e057b8@143.198.36.225:26656"
```

### 4. Start the node
The basic command to start your node is:
```bash copy
namada node ledger run
```
You can check the section in the docs on [Running a full node](https://docs.namada.net/operators/ledger) for further info, including logging options and running your node pesistently in the background using `systemd`.

### 5. (Optional) Use a snapshot for faster syncing
Rather than syncing your node from the first block, you can use a snapshot taken from a recent block height. The [landing page](https://testnet.luminara.icu) will have a download link to a recent snapshot in `tar.lz4` format.  

To apply the snapshot:
1. Stop your node
2. Run `sudo apt install lz4` if lz4 is not already installed on your system
3. Download the `tar.lz4` snapshot file from the testnet landing page. The filename will look something like `luminara-position.5eef10f5ab83_2024-06-28T13.39.tar.lz4`, but the actual filename will differ depending on the chain-id and time the snapshot was created.
```bash copy
wget {filename}
```
4. Extract the contents to a temp directory of your choice:
```bash copy
mkdir ~/namada-temp
lz4 -c -d {filename}.tar.lz4  | tar -x -C ~/namada-temp
```
5. If your node is a validator, back up your `priv_validator_state.json` file at this point. (This step is not necessary if you are only running a full node.)
6. Copy the extracted `db` directory to `{namada-dir}/$CHAIN_ID/` (overwrite the existing `db` directory) and copy the `cometbft/data` directory to `{namada-dir}/$CHAIN_ID/cometbft/` (overwrite the existing `data` directory):
```bash copy
NAMADA_DIR=~/.local/share/namada
sudo cp -a namada-temp/db/ $NAMADA_DIR/$CHAIN_ID
sudo cp -a namada-temp/cometbft/data $NAMADA_DIR/$CHAIN_ID/cometbft
```
7. If you backed up your `priv_validator_state.json` file in step 5, move it back to its original location at `$NAMADA_DIR/$CHAIN_ID/cometbft/data/priv_validator_state.json`.
8. Restart your node. Verify that it is syncing again by checking the logs. It should now be syncing from the height at which the snapshot was taken.
9. You can safely delete the downloaded `tar.lz4` file and the extracted files from step 4.
```bash copy
rm -rf ~/namada-temp
rm {filename}.tar.lz4
```

### 6. (Optional) Become a validator
**Note:** Detailed instructions can be found in the [Post Genesis Validators](https://docs.namada.net/operators/validators/validator-setup#post-genesis-validators) section of the Namada Docs.  

1. Before initializing your validator, you must have a full node that is fully synced to the head of the chain.
2. Create an implicit account, choosing any alias you like:
```bash copy
IMPLICIT_ALIAS=my-implicit
namadaw gen --alias $IMPLICIT_ALIAS
```
3. Get some tokens from the [testnet faucet](https://faucet.luminara.icu) (you will need tokens both to cover transaction gas costs and to stake to your validator).  
First, find the address of the account you created in the previous step:
```bash copy
namadaw list --addr
```
Then, proceed to the [faucet](https://faucet.luminara.icu) and request 1000 tokens to that address. You can check that the tokens arrived in your account with:
```bash copy
namadac balance --owner $IMPLICIT_ALIAS --token nam
```
4. Create your validator with an on-chain transaction using the below command (the `email` parameter is required; however, for testnet you can simply provide a made-up email address). As before, we need to choose a wallet alias (`$VALIDATOR_ALIAS) for our newly created account.
```bash copy
VALIDATOR_ALIAS=testnet-validator
EMAIL=nobody@gmail.com
namadac init-validator \
  --commission-rate 0.05 \
  --max-commission-rate-change 0.01 \
  --email $EMAIL \
  --alias $VALIDATOR_ALIAS \
  --account-keys $IMPLICIT_ALIAS \
  --signing-keys $IMPLICIT_ALIAS \
  --threshold 1
```
5. Optionally, you can also provide other info to identify your validator including a name, logo, website, etc. (this can be done during `init-validator` or later on with the [`change-metadata`](https://docs.namada.net/operators/validators/validator-actions#metadata-changes) command).
6. Restart your node (you will be unable to sign blocks until after you do so).
7. Bond some tokens to your validator. It will take two epochs (equal to the `pipeline_len`) after bonding before your validator becomes active.  

Use this command to bond tokens from your implicit account to your validator:
```bash copy
IMPLICIT_ALIAS=my-implicit
VALIDATOR_ALIAS=testnet-validator
AMOUNT=100
namadac bond \
  --source $IMPLICIT_ALIAS \
  --validator $VALIDATOR_ALIAS \
  --amount $AMOUNT
```