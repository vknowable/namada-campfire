#!/usr/bin/env bash

# Run this script after the chain is running to write the namada-interface .env file, rebuild and start the container.
# Note: as this rebuilds the container it takes some time to complete
REPO_DIR="$HOME/namada-interface"
INTERFACE_DIR="apps/namadillo"


### Grab the repo
rm -rf ~/namada-interface
cd ~
#git clone -b v0.1.0-0e77e71 https://github.com/anoma/namada-interface.git
git clone -b main https://github.com/anoma/namada-interface.git

#cd $HOME/namada-interface && git checkout 1ed4d1285ffbf654c84a80353537023ba98e0614
cd $HOME/namada-interface && git fetch --all && git checkout main && git pull
cp $HOME/namada-campfire/docker/container-build/namada-interface/Dockerfile $REPO_DIR/Dockerfile-interface
cp $HOME/namada-campfire/docker/container-build/namada-interface/nginx.conf $REPO_DIR/nginx.conf



export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")

source $HOME/campfire.env

# write env file
env_file="$REPO_DIR/$INTERFACE_DIR/.env"
{
    echo "NODE_ENV=\"development\""
    echo "NAMADA_INTERFACE_LOCAL=\"false\""

    echo "NAMADA_INTERFACE_NAMADA_ALIAS=\"Campfire Testnet\""
    echo "NAMADA_INTERFACE_NAMADA_TOKEN=\"$NAM\""
    echo "NAMADA_INTERFACE_NAMADA_CHAIN_ID=\"$CHAIN_ID\""
    echo "NAMADA_INTERFACE_NAMADA_URL=\"https://rpc.$DOMAIN:443\""
    echo "NAMADA_INTERFACE_NAMADA_BECH32_PREFIX=\"tnam\""
    echo "NAMADA_INTERFACE_INDEXER_URL=\"https://indexer.$DOMAIN:443\""

    echo "NAMADA_INTERFACE_NAMADA_FAUCET_ADDRESS=https://api.faucet.$DOMAIN"
    echo "NAMADA_INTERFACE_NAMADA_FAUCET_LIMIT=1000"

} > "$env_file"


docker stop interface && docker rm interface
docker build -f $REPO_DIR/Dockerfile-interface -t interface:local $REPO_DIR
docker run --name interface -d -p "3000:80" interface:local