# Run a Node (Using Docker)

**Ready to join [Campfire](https://testnet.luminara.icu), our community-run Namada testnet?** 🏕️  

**Here's how to run a node (using Docker):**  

*Note: you can view the general docs for Namada [here](https://docs.namada.net).*  

### 1. Choose a location for the Namada chain data
We'll use this directory in the example below, but you can choose a different location:
```bash copy
NAMADA_DIR=$HOME/namada-data
mkdir $NAMADA_DIR
```

### 2. Set the appropriate directory permissions
Since the `namada` user inside the Docker container, which has a user-id of `1000`, needs to write to the directory we've just created, we need to change the permissions to allow it to do so.
```bash copy
sudo chown 1000:1000 $NAMADA_DIR
```

### 3. Download the Docker image from the GitHub container registry
We'll assume you're using the Docker image from [here](https://github.com/anoma/namada/pkgs/container/namada) in the following steps. Pull the image for whichever version of Namada is being used for the current testnet (you can find which version you need by checking the Campfire [landing page](https://testnet.luminara.icu)).
```bash copy
NAMADA_VERSION=v0.39.0 # or whichever version you wish to download
docker pull ghcr.io/anoma/namada:namada-$NAMADA_VERSION
```
In this case, the full name of the downloaded image is `ghcr.io/anoma/namada:namada-v0.39.0`.  

We can save the image name to a shell variable for convenience:
```bash copy
export DOCKER_IMAGE=ghcr.io/anoma/namada:namada-$NAMADA_VERSION
```

### 4. Get the current chain-id
Check the Campfire [landing page](https://testnet.luminara.icu); you will need the current chain-id in the following steps.
```bash copy
CHAIN_ID={chain-id-here}
```

### 5. Initialize your node (`join-network`)
This command will run `join-network` using the data directory we created in the first step:
```bash copy
docker run --rm -P -i -e NAMADA_NETWORK_CONFIGS_SERVER="https://testnet.luminara.icu/configs" -v $NAMADA_DIR:/home/namada/.local/share/namada -t $DOCKER_IMAGE client utils join-network --chain-id $CHAIN_ID --dont-prefetch-wasm
```

### 6. Download the chain WASM files
Download and extract the wasm files from the link on the [landing page](https://testnet.luminara.icu):
```bash copy
wget -O - https://testnet.luminara.icu/wasm.tar.gz | tar -xz -C $NAMADA_DIR/$CHAIN_ID/wasm/ --strip-components=1
```

### 7. Add `persistent_peers`
Find the persistent peer address on the [landing page](https://testnet.luminara.icu) and add it to your node's config file:  
*Note: below is an example value; yours will be slightly different*
```bash copy
# in file $NAMADA_DIR/$CHAIN_ID/config.toml
persistent_peers = "tcp://af427e348cd45dd7308be4ea58f1492098e057b8@143.198.36.225:26656"
```

### 8. Start the node
In this command we are naming our container `namada` for easy reference later, but you can choose a different name.  

This command will start the node:
```bash copy
docker run --name namada -d -P -v $NAMADA_DIR:/home/namada/.local/share/namada $DOCKER_IMAGE node ledger run
```

The node should now be syncing in the background. You can verify its operation by checking the logs:
```bash copy
docker logs -f namada
```

You should see entries to indicate new blocks are being indexed, similar to:
```bash
2024-06-28T13:38:15.442871Z  INFO namada_node::shell: Committed block hash: d958f287c38dbeb94e07dfb8290c9c620753157510ff1d46899925def0df0b99, height: 798
```

### 9. (Optional) Use a snapshot for faster syncing
Rather than syncing your node from the first block, you can use a snapshot taken from a recent block height. The [landing page](https://testnet.luminara.icu) will have a download link to a recent snapshot in `tar.lz4` format.  

To apply the snapshot:
1. Stop your node:
```bash copy
docker stop namada
```
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
sudo cp -a namada-temp/db/ $NAMADA_DIR/$CHAIN_ID
sudo cp -a namada-temp/cometbft/data $NAMADA_DIR/$CHAIN_ID/cometbft
```
7. If you backed up your `priv_validator_state.json` file in step 5, move it back to its original location at `$NAMADA_DIR/$CHAIN_ID/cometbft/data/priv_validator_state.json`.
8. Since we have modified the contents of the chain-data directory `$NAMADA_DIR`, ensure that the permissions have once again been set to allow our container write access:
```bash copy
sudo chown -R 1000:1000 $NAMADA_DIR
```
8. Restart your node:
```bash copy
docker restart namada
```
Verify that it is syncing again by checking the logs. It should now be syncing from the height at which the snapshot was taken.
```bash copy
docker logs -f namada
```
9. You can safely delete the downloaded `tar.lz4` file and the extracted files from step 4.
```bash copy
rm -rf ~/namada-temp
rm {filename}.tar.lz4
```

### 10. (Optional) Become a validator
**Note:** Detailed instructions can be found in the [Post Genesis Validators](https://docs.namada.net/operators/validators/validator-setup#post-genesis-validators) section of the Namada Docs.  

1. Before initializing your validator, you must have a full node that is fully synced to the head of the chain.
2. Rather than running commands using `docker run`, it will be easier to perform the validator setup actions using a shell inside the container. Run the following command to start a bash session inside the container; you should see your command prompt change to something like `namada@cedf19f0200e:/$`:
```bash copy
docker exec -it namada /bin/bash
```
3. Create an implicit account, choosing any alias you like:
```bash copy
IMPLICIT_ALIAS=my-implicit
namadaw gen --alias $IMPLICIT_ALIAS
```
4. Get some tokens from the [testnet faucet](https://faucet.luminara.icu) (you will need tokens both to cover transaction gas costs and to stake to your validator).  
First, find the address of the account you created in the previous step:
```bash copy
namadaw list --addr
```
Then, proceed to the [faucet](https://faucet.luminara.icu) and request 1000 tokens to that address. You can check that the tokens arrived in your account with:
```bash copy
namadac balance --owner $IMPLICIT_ALIAS --token nam
```
5. Create your validator with an on-chain transaction using the below command (the `email` parameter is required; however, for testnet you can simply provide a made-up email address). As before, we need to choose a wallet alias (`$VALIDATOR_ALIAS) for our newly created account.
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
6. Optionally, you can also provide other info to identify your validator including a name, logo, website, etc. (this can be done during `init-validator` or later on with the [`change-metadata`](https://docs.namada.net/operators/validators/validator-actions#metadata-changes) command).
7. Restart your node (you will be unable to sign blocks until after you do so).  

End your container shell session and return to your system command prompt:
```bash copy
exit
```

Restart the container:
```bash copy
docker restart namada
```

8. Bond some tokens to your validator. It will take two epochs (equal to the `pipeline_len`) after bonding before your validator becomes active.

Re-enter your container shell:
```bash copy
docker exec -it namada /bin/bash
```
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
