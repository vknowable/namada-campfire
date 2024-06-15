#!/usr/bin/env bash

# Run this script after the chain is running to configure and launch namadexer


# requisites
sudo apt update
sudo apt install -y snapd
sudo snap install yq


# Grab the repo
rm -rf ~/namada-indexer
cd ~
git clone -b main https://github.com/anoma/namada-indexer.git
cd $HOME/namada-indexer && git fetch --all && git checkout main && git pull


# prep are vars
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export CHAIN_PREFIX="${CHAIN_ID%%.*}"
export TENDERMINT_URL="http://172.17.0.1:26657"
export NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")


# update the values for this chain in the docker compose file
yq -i ".services[].environment.TENDERMINT_URL = \"$TENDERMINT_URL\"" $HOME/namada-indexer/docker-compose.yml
yq -i ".services[].environment.CHAIN_ID = \"$CHAIN_ID\"" $HOME/namada-indexer/docker-compose.yml
yq -i ".services[].environment.DATABASE_URL = \"postgres://postgres:password@postgres:5432/namada-indexer\"" $HOME/namada-indexer/docker-compose.yml
yq -i '.services.webserver.ports[] |= sub("5000:5000", "6000:5000")' $HOME/namada-indexer/docker-compose.yml

# add these values
yq -i '.services.chain.environment.INITIAL_QUERY_RETRY_TIME = "60"' $HOME/namada-indexer/docker-compose.yml
yq -i '.services.chain.environment.CHECKSUMS_FILE = "checksums.json"' $HOME/namada-indexer/docker-compose.yml


# copy checksums.json
cp -f $HOME/chaindata/namada-1/$CHAIN_ID/wasm/checksums.json $HOME/namada-indexer/checksums.json


# bring down any existing volumes
cd $HOME/namada-indexer
docker compose -f docker-compose.yml down --volumes

# bring up the containers
docker compose -f docker-compose.yml up -d





### OLD namadexer


# cd $HOME/namadexer/contrib && docker compose down --volumes

# # create new config file
# sed -i "s#^tendermint_addr = \".*\"#tendermint_addr = \"$TENDERMINT_URL\"#" "$HOME/namadexer/config/Settings.toml"
# cp -f $HOME/namadexer/config/Settings.example.toml $HOME/namadexer/config/Settings.toml
# sed -i '0,/^host = \".*\"/s//host = "postgres"/' "$HOME/namadexer/config/Settings.toml"
# sed -i "s#^chain_name = \".*\"#chain_name = \"$CHAIN_PREFIX\"#" "$HOME/namadexer/config/Settings.toml"
# sed -i "s#^tendermint_addr = \".*\"#tendermint_addr = \"$TENDERMINT_URL\"#" "$HOME/namadexer/config/Settings.toml"

# # copy checksums.json
# cp -f $HOME/chaindata/namada-1/$CHAIN_ID/wasm/checksums.json $HOME/namadexer/contrib/checksums.json

# # launch
# cd $HOME/namadexer/contrib && docker compose up -d
