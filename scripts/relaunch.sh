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
  read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi


echo "**************************************************************************************"
echo "Destroying old chain and components..."
echo "**************************************************************************************"

echo "Stopping and removing:"


namada_containers=("interface" "namada-indexer" "faucet-" "compose-namada-")

for container in "${namada_containers[@]}"; do

  docker_ids=$(docker container ls --all | grep "$container" | awk '{print $1}')

  if [ -n "$docker_ids" ]; then
    echo "Stopping container: '$container'..."
    docker container stop $docker_ids

    echo "Removing container: '$container'..."
    docker container rm --force $docker_ids
  else
    echo "No container found matching: '$container'."
  fi

done


if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "Should we wipe and rebuild all namada component images (namada, faucet, interface)?"
  echo "**************************************************************************************"
  read -p "This is not necessary, but would you like to wipe these component images? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ [Yy]$ ]]; then
    
    namada_containers=("interface" "faucet-" "namada")

    for image in "${namada_containers[@]}"; do
      image_ids=$(docker image ls --all | grep "$image" | awk '{print $3}')
      if [ -n "$image_ids" ]; then
        echo "Removing images: '$image'..."
        docker image rm --force $image_ids
      else
        echo "No image found matching: '$image'."
      fi
    done

  fi
fi



echo "Removing validators:"
docker compose -f $HOME/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file $HOME/campfire.env down --volumes
sudo rm -rf $HOME/chaindata

echo "Done"






echo "**************************************************************************************"
echo "Relaunching validator nodes..."
echo "**************************************************************************************"

# check for existing campfire.env file and ask if we want to use it
export USE_EXISTING_ENV="n"
if [ -e "$HOME/campfire.env" ]; then
  source $HOME/campfire.env
  if [ ! -z "$NAMADA_TAG" ] && [ ! -z "$CHAIN_PREFIX" ] && [ ! -z "$EXTIP" ] && [ ! -z "$P2P_PORT" ] && [ ! -z "$RPC_PORT" ] && [ ! -z "$DOMAIN" ] && [ ! -z "$SELF_BOND_AMT" ] && [ ! -z "$GENESIS_DELAY_MINS" ]; then
    cat $HOME/campfire.env
    echo ""
    read -p "Found existing configuration file $HOME/campfire.env. Do you want to use it? (y/n): " USE_EXISTING_ENV
  fi
fi

# check for existing .env configuration file
if [ "$USE_EXISTING_ENV" = "y" ]; then
  echo "Using configuration file $HOME/campfire.env"
  source $HOME/campfire.env
else

  echo "Let's set up a new configuration file $HOME/campfire.env"

  echo "Select the Namada version to use for the new chain, found here: https://github.com/anoma/namada/releases"
  read -p "Enter the Namada version to use for the new chain (eg: v0.39.0): " NAMADA_TAG
  export NAMADA_TAG=$NAMADA_TAG

  read -p "Enter the chain-id prefix (eg: luminara): " CHAIN_PREFIX
  export CHAIN_PREFIX=$CHAIN_PREFIX

  read -p "Enter the public ip of the server (eg: 142.32.13.100): " EXTIP
  export EXTIP=$EXTIP

  read -p "Enter the P2P port of the server (eg: 26656): " P2P_PORT
  export P2P_PORT=$P2P_PORT

  read -p "Enter the RPC port of the server (eg: 26657): " RPC_PORT
  export RPC_PORT=$RPC_PORT

  read -p "Enter the server domain name (eg: luminara.icu): " DOMAIN
  export DOMAIN=$DOMAIN

  read -p "Enter the genesis validators self-bond-amount (eg: 1000000000): " SELF_BOND_AMT
  export SELF_BOND_AMT=$SELF_BOND_AMT

  read -p "Enter the genesis delay time in minutes (eg: 1): " GENESIS_DELAY_MINS
  export GENESIS_DELAY_MINS=$GENESIS_DELAY_MINS

fi


# check if docker image already exists for that version -- if not build it
if docker images | grep -q "namada\s*$NAMADA_TAG"; then
  echo "Image for namada:$NAMADA_TAG found. Continuing..."
else
  echo "Building image for namada:$NAMADA_TAG..."
  docker build -t namada:$NAMADA_TAG -f $HOME/namada-campfire/docker/container-build/namada/Dockerfile --build-arg NAMADA_TAG=$NAMADA_TAG --build-arg BUILD_WASM=true .
  echo "Build complete. Continuing..."
fi


# always save last settings
# save configuration for next time
CONFIG_OUTPUT_FILE="$HOME/campfire.env"
echo "NAMADA_TAG=$NAMADA_TAG" > "$CONFIG_OUTPUT_FILE"
echo "CHAIN_PREFIX=$CHAIN_PREFIX" >> "$CONFIG_OUTPUT_FILE"
echo "EXTIP=$EXTIP" >> "$CONFIG_OUTPUT_FILE"
echo "P2P_PORT=$P2P_PORT" >> "$CONFIG_OUTPUT_FILE"
echo "RPC_PORT=$RPC_PORT" >> "$CONFIG_OUTPUT_FILE"
echo "DOMAIN=$DOMAIN" >> "$CONFIG_OUTPUT_FILE"
echo "SELF_BOND_AMT=$SELF_BOND_AMT" >> "$CONFIG_OUTPUT_FILE"
echo "GENESIS_DELAY_MINS=$GENESIS_DELAY_MINS" >> "$CONFIG_OUTPUT_FILE"

# with rapport
echo "Configuration saved to $CONFIG_OUTPUT_FILE"

# always build with .env file
docker compose -f $HOME/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file $HOME/campfire.env up -d


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



if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "The following steps would be to (re)launch the faucet, indexer, and interface!"
  echo "**************************************************************************************"
  read -p "Would you like to execute these steps? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ [Yy]$ ]]; then
    # Include adjacent launch-.sh scripts
    export LOGS_NOFOLLOW=true
    $HOME/namada-campfire/scripts/launch-faucet-be.sh
    $HOME/namada-campfire/scripts/launch-faucet-fe.sh
    # $HOME/namada-campfire/scripts/launch-indexer.sh
    # $HOME/namada-campfire/scripts/launch-interface.sh
  fi
fi



echo "Done"
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
echo "**************************************************************************************"
echo "Campfire relaunched!"
echo "Chain-id: $CHAIN_ID"
echo "Namada version: $NAMADA_TAG"
echo "Run 'docker logs -f compose-namada-1-1' to see logs"
echo "**************************************************************************************"
