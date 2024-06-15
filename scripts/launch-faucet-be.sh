#!/usr/bin/env bash

### Grab the repo
rm -rf $HOME/namada-faucet
cd $HOME
git clone -b campfire-faucet https://github.com/vknowable/namada-faucet.git


# Copy over the docker file
cp -f $HOME/namada-campfire/docker/container-build/faucet-backend/Dockerfile $HOME/namada-faucet/Dockerfile    


# Build
cd $HOME/namada-faucet
docker build -t faucet-be:local .


# Tear down any
docker stop $(docker container ls --all | grep 'faucet-be' | awk '{print $1}')
docker container rm --force $(docker container ls --all | grep 'faucet-be' | awk '{print $1}')


# Fetch the faucet private key
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export FAUCET_PK=$(awk '/\[secret_keys\]/ {found=1} found && /faucet-1 = / {gsub(/.*= "/, ""); sub(/"$/, ""); sub(/unencrypted:/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")


# Start the faucet backend
cd $HOME/namada-faucet
docker run --name faucet-be -d --network host faucet-be:local ./server --cargo-env development --difficulty 3 --private-key $FAUCET_PK --chain-start 1 --chain-id $CHAIN_ID --port 5000 --rps 10 --rpc http://127.0.0.1:26657

echo "**************************************************************************************"
echo "Following faucet backend logs, feel free to press Ctrl+C to exit!"
docker logs -f $(docker container ls --all | grep faucet-be | awk '{print $1}')
