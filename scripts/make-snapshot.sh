#!/usr/bin/env bash

# This script will stop the namada-2 node, create a snapshot using it's db contents, and restart the node

HTML_PATH="/usr/share/nginx/html"
DOMAIN=$(grep -oP '(?<=href="https://testnet.).*?(?=/)' "$HTML_PATH/index.html" | head -1)
CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-2/global-config.toml")
SNAP_TIME=$(date -u +"%Y-%m-%dT%H.%M")
SNAP_FILENAME="${CHAIN_ID}_${SNAP_TIME}.tar.lz4"

docker stop compose-namada-2-1
sudo tar -C $HOME/chaindata/namada-2/$CHAIN_ID -cf - db cometbft/data | lz4 - $HOME/$SNAP_FILENAME
sudo rm -f $HTML_PATH/*.tar.lz4
sudo mv -f $HOME/$SNAP_FILENAME $HTML_PATH/$SNAP_FILENAME
sudo sed -i.bak -e "s|Snapshot: <a href=\".*\">Download</a>|Snapshot: <a href=\"https://testnet.$DOMAIN/$SNAP_FILENAME\">Download</a>|" "$HTML_PATH/index.html"
docker start compose-namada-2-1