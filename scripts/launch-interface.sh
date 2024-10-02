#!/usr/bin/env bash

# Run this script after the chain is running to write the namada-interface .env file, rebuild and start the container.
# Note: as this rebuilds the container it takes some time to complete
REPO_NAME="namada-interface"
REPO_DIR="$HOME/$REPO_NAME"
INTERFACE_DIR="apps/namadillo"


### Grab the repo
rm -rf ~/namada-interface
cd $HOME
#git clone -b v0.1.0-0e77e71 https://github.com/anoma/namada-interface.git
git clone -b main https://github.com/anoma/$REPO_NAME.git

#cd $HOME/namada-interface && git checkout 1ed4d1285ffbf654c84a80353537023ba98e0614
cd $REPO_DIR && git fetch --all && git checkout main && git pull
cp -f $HOME/namada-campfire/docker/container-build/namada-interface/Dockerfile $REPO_DIR/Dockerfile-interface
#cp -f $REPO_DIR/docker/namadillo/Dockerfile $REPO_DIR/Dockerfile-interface # needs help with writing the config
#cp -f $HOME/namada-campfire/docker/container-build/namada-interface/nginx.conf $REPO_DIR/nginx.conf



export CAMPFIRE_CHAIN_DATA="$HOME/chaindata/namada-1"
export CHAIN_DATA=${CHAIN_DATA:-$CAMPFIRE_CHAIN_DATA}


export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$CHAIN_DATA/global-config.toml")
export NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$CHAIN_DATA/$CHAIN_ID/wallet.toml")
export FAUCET_ADDRESS=$(awk '/\[addresses\]/ {found=1} found && /faucet-1 = / {gsub(/.*= "/, ""); sub(/"$/, ""); sub(/unencrypted:/, ""); print; exit}' "$CHAIN_DATA/$CHAIN_ID/wallet.toml")


# Load Campfire vars in environment
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
    echo "RPC_URL=\"https://rpc.$DOMAIN:443\"" # used for bootstrap_config.sh
    
    echo "NAMADA_INTERFACE_NAMADA_BECH32_PREFIX=\"tnam\""
    echo "NAMADA_INTERFACE_INDEXER_URL=\"https://indexer.$DOMAIN:443\""
    echo "INDEXER_URL=\"https://indexer.$DOMAIN:443\"" # used for bootstrap_config.sh

    echo "REACT_APP_NAMADA_FAUCET_ADDRESS=\"$FAUCET_ADDRESS\""
    echo "NAMADA_INTERFACE_NAMADA_FAUCET_ADDRESS=\"$FAUCET_ADDRESS\""
    echo "NAMADA_INTERFACE_NAMADA_FAUCET_LIMIT=1000"

} > "$env_file"


# This was the template file for Namadillo config.
#cp -f $REPO_DIR/docker/.namadillo.config.toml $REPO_DIR/docker/namadillo.config.toml

# This is the template file for Namadillo config.
# write config file
config_file="$REPO_DIR/$INTERFACE_DIR/public/config.toml"
{
    echo "indexer_url = \"https://indexer.$DOMAIN:443\""
    echo "rpc_url = \"https://rpc.$DOMAIN:443\""
} > "$config_file"

# tear down
docker stop $(docker container ls --all | grep 'interface' | awk '{print $1}')
docker container rm --force $(docker container ls --all | grep 'interface' | awk '{print $1}')
if [ -z "${LOGS_NOFOLLOW}" ]; then
    docker image rm --force $(docker image ls --all | grep 'interface' | awk '{print $3}')
fi

# load Namadillo env vars, build, and run
source $env_file
docker build -f $REPO_DIR/Dockerfile-interface --build-arg INDEXER_URL="$INDEXER_URL" --build-arg RPC_URL="$RPC_URL" -t interface:local $REPO_DIR
docker run --name interface -d --env-file $env_file -p "3000:80" interface:local


if [ -z "${LOGS_NOFOLLOW}" ]; then
    echo "**************************************************************************************"
    echo "Following interface logs, feel free to press Ctrl+C to exit!"
    docker logs -f $(docker container ls --all | grep interface | awk '{print $1}')
fi