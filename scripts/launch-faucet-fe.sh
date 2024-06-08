#!/usr/bin/env bash

### Grab the repo
rm -rf ~/namada-interface
cd ~
git clone -b v0.1.0-0e77e71 https://github.com/anoma/namada-interface.git


# Copy over the files for docker and nginx
cp ~/namada-campfire/docker/container-build/faucet-frontend/Dockerfile ~/namada-interface/Dockerfile    
mkdir -p ~/namada-interface/apps/faucet/docker
cp ~/namada-campfire/docker/container-build/faucet-frontend/nginx.conf ~/namada-interface/apps/faucet/docker/nginx.conf


# Build
cd ~/namada-interface
docker build -t faucet-fe:local .


# Tear down any
docker stop $(docker container ls --all | grep 'faucet-fe' | awk '{print $1}')
docker container rm --force $(docker container ls --all | grep 'faucet-fe' | awk '{print $1}')


# Prepare the environment variables
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")

# write env file
env_file=~/namada-interface/apps/faucet/.env
{
    echo "REACT_APP_FAUCET_API_ENDPOINT=https://api.faucet.knowable.run"
    echo "REACT_APP_FAUCET_API_ENDPOINT=/api/v1/faucet"
    echo "REACT_APP_FAUCET_LIMIT=1000"
    echo "REACT_APP_TOKEN_NAM=$NAM"
} > "$env_file"


# Start the faucet backend
cd ~/namada-faucet
docker run --name faucet-fe -d -p "4000:80" faucet-fe:local

echo "**************************************************************************************"
echo "Following faucet frontend logs, feel free to press Ctrl+C to exit!"
docker logs -f $(docker container ls --all | grep faucet-fe | awk '{print $1}')

