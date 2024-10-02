#!/usr/bin/env bash

### Grab the repo
rm -rf $HOME/namada-faucet
cd $HOME
#git clone -b campfire-faucet https://github.com/sirouk/namada-faucet.git
#git clone -b master https://github.com/heliaxdev/namada-faucet
git clone -b campfire-faucet https://github.com/vknowable/namada-faucet.git


# Copy over the docker file
cp -f $HOME/namada-campfire/docker/container-build/faucet-backend/Dockerfile $HOME/namada-faucet/Dockerfile    


# Tear down any
docker stop $(docker container ls --all | grep 'faucet-be' | awk '{print $1}')
if [ -z "${LOGS_NOFOLLOW}" ]; then
    docker container rm --force $(docker container ls --all | grep 'faucet-be' | awk '{print $1}')
fi


# Fetch the faucet private key
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export FAUCET_PK=$(awk '/\[secret_keys\]/ {found=1} found && /faucet-1 = / {gsub(/.*= "/, ""); sub(/"$/, ""); sub(/unencrypted:/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")


# to get our $DOMAIN
source $HOME/campfire.env

# write env file
env_file=$HOME/namada-faucet/.env
{

    echo "PORT=5000"
    echo "DIFFICULTY=1"
    echo "PRIVATE_KEY=$FAUCET_PK"
    echo "CHAIN_START=1"
    echo "CHAIN_ID=$CHAIN_ID"
    echo "RPC=http://127.0.0.1:26657"
    echo "WITHDRAW_LIMIT=1000"
    #echo "AUTH_KEY=my_auth_key"
    echo "RPS=10"

} > "$env_file"


# Build
cd $HOME/namada-faucet
docker build -t faucet-be:local .


# Start the faucet backend
cd $HOME/namada-faucet
#docker run --name faucet-be -d --network host faucet-be:local ./server --cargo-env development --difficulty 3 --private-key $FAUCET_PK --chain-start 1 --chain-id $CHAIN_ID --port 5000 --rps 10 --rpc http://127.0.0.1:26657
docker run --name faucet-be -d --network host faucet-be:local ./server --difficulty 1 --private-key $FAUCET_PK --chain-start 1 --chain-id $CHAIN_ID --port 5000 --rps 10 --rpc http://127.0.0.1:26657

if [ -z "${LOGS_NOFOLLOW}" ]; then
    echo "**************************************************************************************"
    echo "Following faucet backend logs, feel free to press Ctrl+C to exit!"
    docker logs -f $(docker container ls --all | grep faucet-be | awk '{print $1}')
fi
