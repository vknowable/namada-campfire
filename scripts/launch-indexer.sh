#!/usr/bin/env bash

# Run this script after the chain is running to configure and launch namadexer

CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
CHAIN_PREFIX="${CHAIN_ID%%.*}"
TENDERMINT_URL="http://172.17.0.1:26657"

cd $HOME/namadexer/contrib && docker compose down --volumes

# create new config file
cp $HOME/namadexer/config/Settings.example.toml $HOME/namadexer/config/Settings.toml
sed -i '0,/^host = \".*\"/s//host = "postgres"/' "$HOME/namadexer/config/Settings.toml"
sed -i "s#^chain_name = \".*\"#chain_name = \"$CHAIN_PREFIX\"#" "$HOME/namadexer/config/Settings.toml"
sed -i "s#^tendermint_addr = \".*\"#tendermint_addr = \"$TENDERMINT_URL\"#" "$HOME/namadexer/config/Settings.toml"

# copy checksums.json
cp $HOME/chaindata/namada-1/$CHAIN_ID/wasm/checksums.json $HOME/namadexer/contrib/checksums.json

# launch
cd $HOME/namadexer/contrib && docker compose up -d