#!/usr/bin/env bash

# Run this script after the chain is running to write the namada-interface .env file, rebuild and start the container.
# Note: as this rebuilds the container it takes some time to complete

source $HOME/campfire.env
CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")

cd $HOME/namada-interface && git checkout main
cp $HOME/namada-campfire/docker/container-build/namada-interface/Dockerfile $HOME/namada-interface/Dockerfile-interface
cp $HOME/namada-campfire/docker/container-build/namada-interface/nginx.conf $HOME/namada-interface/nginx.conf

# write env file
env_file="$HOME/namada-interface/apps/namada-interface/.env"
{
    echo "NAMADA_INTERFACE_NAMADA_ALIAS=\"Campfire Testnet\""
    echo "NAMADA_INTERFACE_NAMADA_TOKEN=\"$NAM\""
    echo "NAMADA_INTERFACE_NAMADA_CHAIN_ID=\"$CHAIN_ID\""
    echo "NAMADA_INTERFACE_NAMADA_URL=\"https://rpc.$DOMAIN\""
    echo "NAMADA_INTERFACE_NAMADA_BECH32_PREFIX=tnam"
} > "$env_file"

docker stop interface && docker rm interface
docker build -f $HOME/namada-interface/Dockerfile-interface -t interface:local $HOME/namada-interface
docker run --name interface -d -p "3000:80" interface:local