#!/usr/bin/env bash

# This script will:
# 1. stop and permanently delete any current running chain, chain-data, faucet containers, etc
# 2. relaunch chain and faucet using the specified Namada version

# Confirm destruction of old chain before proceeding unless run with -y
if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "This script will permanently destroy any running Campfire chain components and"
  echo "associated data before attempting to relaunch with a new chain-id."
  echo "This script requires sudo privilege."
  echo "**************************************************************************************"
  read -p "Are you sure you want to proceed? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

read -p "Enter the Namada version to use for the new chain (eg: v0.37.0): " NAMADA_TAG
export NAMADA_TAG=$NAMADA_TAG

# check if docker image already exists for that version -- if not build it
if docker images | grep -q "namada\s*$NAMADA_TAG"; then
  echo "Image for namada:$NAMADA_TAG found. Continuing..."
else
  read -p "Image for namada:$NAMADA_TAG not found. Would you like to build it now? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  else
    docker build -t namada:$NAMADA_TAG -f $HOME/namada-campfire/docker/container-build/namada/Dockerfile --build-arg NAMADA_TAG=$NAMADA_TAG --build-arg BUILD_WASM=true .
    echo "Build complete. Continuing..."
  fi
fi

echo "**************************************************************************************"
echo "Destroying old chain..."
echo "**************************************************************************************"
echo "Stopping:"
docker stop faucet-be
echo "Removing:"
docker rm faucet-be
echo "Stopping:"
docker stop faucet-fe
echo "Removing:"
docker rm faucet-fe
echo "Removing validators:"
docker compose -f $HOME/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file $HOME/campfire.env down --volumes
sudo rm -rf $HOME/chaindata

echo "Done"

echo "**************************************************************************************"
echo "Relaunching validator nodes..."
echo "**************************************************************************************"

# check for existing .env configuration file
if [ -e "$HOME/campfire.env" ]; then
  echo "Using configuration file $HOME/campfire.env"
  docker compose -f ~/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file ~/campfire.env up -d
else
  echo "Could not find expected configuration file $HOME/campfire.env"
  read -p "Enter the public ip of the server (eg: 142.32.13.100): " EXTIP
  export EXTIP=$EXTIP

  read -p "Enter the server domain name (eg: luminara.icu): " DOMAIN
  export DOMAIN=$DOMAIN

  read -p "Enter the chain-id prefix (eg: luminara): " CHAIN_PREFIX
  export CHAIN_PREFIX=$CHAIN_PREFIX

  # save configuration for next time
  CONFIG_OUTPUT_FILE="$HOME/campfire.env"
  echo "EXTIP=$EXTIP" > "$CONFIG_OUTPUT_FILE"
  echo "DOMAIN=$DOMAIN" >> "$CONFIG_OUTPUT_FILE"
  echo "CHAIN_PREFIX=$CHAIN_PREFIX" >> "$CONFIG_OUTPUT_FILE"
  echo "Configuration saved to $CONFIG_OUTPUT_FILE"

  docker compose -f ~/namada-campfire/docker/compose/docker-compose-local-namada.yml -d
fi

echo "Validator nodes started."
echo "Waiting for block 5 before proceeding..."

# wait for block 5 or timeout after 5 mins before proceeding
TIMEOUT=300
END_TIME=$((SECONDS + TIMEOUT))

while [ $SECONDS -lt $END_TIME ]; do
  HEIGHT=$(curl -s localhost:26657/status | jq -r .result.sync_info.latest_block_height)
  echo "Current height = $HEIGHT"
  if [ -n "$HEIGHT" ] && [ "$HEIGHT" -ge 5 ] 2>/dev/null; then
    echo "Continuing..."
    break
  fi
  sleep 5
done

# If the loop timed out
if [ "$SECONDS" -ge "$END_TIME" ]; then
    echo "Error: Timeout after 5 minutes. Block height did not reach 5."
    exit 1
fi

# read chain-id
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
# read faucet private key
# export FAUCET_PK=$(awk '/\[secret_keys\]/ {found=1} found && /faucet-1/ {gsub(/.*unencrypted:/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")
export FAUCET_PK=$(awk '/\[secret_keys\]/ {found=1} found && /faucet-1/ {gsub(/.*unencrypted:/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")

# TODO: read NAM address and verify it equals tnam1q87wtaqqtlwkw927gaff34hgda36huk0kgry692a
# if not, edit faucet-fe .env file and rebuild container

echo "**************************************************************************************"
echo "Starting faucet..."
echo "**************************************************************************************"

# start faucet backend
echo "Backend container-id:"
docker run --name faucet-be -d -p "5000:5000" faucet-be:local ./server \
  --cargo-env development --difficulty 3 --private-key $FAUCET_PK --chain-start 1 \
  --chain-id $CHAIN_ID --port 5000 --rps 10  --rpc http://172.17.0.1:26657

# start faucet frontend
echo "Frontend container-id:"
docker run --name faucet-fe -d -p "4000:80" faucet-fe:local

echo "Done"

echo "**************************************************************************************"
echo "Campfire relaunched!"
echo "Chain-id: $CHAIN_ID"
echo "Namada version: $NAMADA_TAG"
echo "Run 'docker logs -f compose-namada-1-1' to see logs"
echo "**************************************************************************************"
