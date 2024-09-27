#!/usr/bin/env bash


# Grab the repo
rm -rf ~/namada-indexer
cd ~
git clone -b main https://github.com/anoma/namada-indexer.git
cd $HOME/namada-indexer && git fetch --all && git checkout main && git pull


# prep are vars
export DATABASE_URL="postgres://postgres:password@postgres:5432/namada-indexer"
export TENDERMINT_URL="http://172.17.0.1:26657"
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export CACHE_URL="redis://dragonfly:6379"
export WEBSERVER_PORT="6000"


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
} > "$env_file"

# copy checksums.json
cp -f $HOME/chaindata/namada-1/$CHAIN_ID/wasm/checksums.json $HOME/namada-indexer/checksums.json


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
docker compose -f $HOME/namada-indexer/docker-compose.yml --env-file $HOME/namada-indexer/.env up -d
