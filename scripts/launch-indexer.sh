#!/usr/bin/env bash


# Grab the repo
rm -rf ~/namada-indexer
cd ~
git clone -b main https://github.com/anoma/namada-indexer.git
cd $HOME/namada-indexer && git fetch --all && git checkout main && git pull
#cd $HOME/namada-indexer && git fetch --all && git checkout chore/update-namada-to-0.43.0 && git pull


# prep are vars
export DATABASE_URL="postgres://postgres:password@postgres:5432/namada-indexer"
export TENDERMINT_URL="http://172.17.0.1:26657"
export FOUND_CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export CHAIN_ID=${CHAIN_ID:-$FOUND_CHAIN_ID}
export CACHE_URL="redis://dragonfly:6379"
export WEBSERVER_PORT="6000"

echo "Proceeding with CHAIN_ID: $CHAIN_ID, TENDERMINT_URL: $TENDERMINT_URL"


# update the values for this chain in the docker compose file
#yq -i ".services[].environment.DATABASE_URL = \"postgres://postgres:password@postgres:5432/namada-indexer\"" $HOME/namada-indexer/docker-compose.yml
#yq -i ".services[].environment.TENDERMINT_URL = \"$TENDERMINT_URL\"" $HOME/namada-indexer/docker-compose.yml
#yq -i ".services[].environment.CHAIN_ID = \"$CHAIN_ID\"" $HOME/namada-indexer/docker-compose.yml
#yq -i '.services.webserver.ports[] |= sub("5000:5000", "6000:5000")' $HOME/namada-indexer/docker-compose.yml

# add these values
#yq -i '.services.chain.environment.INITIAL_QUERY_RETRY_TIME = "60"' $HOME/namada-indexer/docker-compose.yml
#yq -i '.services.chain.environment.CHECKSUMS_FILE = "checksums.json"' $HOME/namada-indexer/docker-compose.yml


# output vars to .env in root of namada-indexer
env_file="$HOME/namada-indexer/.env"
{
    echo "DATABASE_URL=\"$DATABASE_URL\""
    echo "TENDERMINT_URL=\"$TENDERMINT_URL\""
    echo "CHAIN_ID=\"$CHAIN_ID\""
    echo "CACHE_URL=\"$CACHE_URL\""
    echo "WEBSERVER_PORT=\"$WEBSERVER_PORT\""
    echo "PORT=\"$WEBSERVER_PORT\""
} > "$env_file"

# copy checksums.json

export CAMPFIRE_CHAINDATA=$HOME/chaindata/namada-1/$CHAIN_ID
export CHAINDATA_PATH=${CHAINDATA_PATH:-$CAMPFIRE_CHAINDATA}
cp -f $CHAINDATA_PATH/wasm/checksums.json $HOME/namada-indexer/checksums.json
echo "Copied $CHAINDATA_PATH/wasm/checksums.json"


# restart node with read_past_height_limit adjustment
sed -i 's#^read_past_height_limit = .*#read_past_height_limit = 360000#' $CHAINDATA_PATH/config.toml
# echo output about the change and restart
echo "Changed read_past_height_limit to 360000 in $CHAINDATA_PATH/config.toml, restarting node..."
docker container restart compose-namada-1-1


# bring down any existing volumes
cd $HOME/namada-indexer

# tear down
docker compose -f docker-compose.yml down --volumes
docker stop $(docker container ls --all | grep 'namada-indexer' | awk '{print $1}')
docker container rm --force $(docker container ls --all | grep 'namada-indexer' | awk '{print $1}')
if [ -z "${LOGS_NOFOLLOW}" ]; then
    docker image rm --force $(docker image ls --all | grep 'namada-indexer' | awk '{print $3}')
fi

# build and start the containers
#docker compose -f docker-compose.yml up --env-file $HOME/namada-indexer/.env -d
docker compose -f $HOME/namada-indexer/docker-compose.yml --env-file $HOME/namada-indexer/.env up -d





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
