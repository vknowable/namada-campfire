#!/usr/bin/env bash

### Grab the repo
rm -rf $HOME/namada-interface
cd $HOME
#git clone -b v0.1.0-0e77e71 https://github.com/anoma/namada-interface.git
git clone -b main https://github.com/anoma/namada-interface.git
#git clone -b main https://github.com/anoma/namada-interface.git


# Copy over the files for docker and nginx
cp -f $HOME/namada-campfire/docker/container-build/faucet-frontend/Dockerfile $HOME/namada-interface/Dockerfile    
mkdir -p $HOME/namada-interface/apps/faucet/docker
cp -f $HOME/namada-campfire/docker/container-build/faucet-frontend/nginx.conf $HOME/namada-interface/apps/faucet/docker/nginx.conf


# Prepare the environment variables
export CHAIN_ID=$(awk -F'=' '/default_chain_id/ {gsub(/[ "]/, "", $2); print $2}' "$HOME/chaindata/namada-1/global-config.toml")
export NAM=$(awk '/\[addresses\]/ {found=1} found && /nam = / {gsub(/.*= "/, ""); sub(/"$/, ""); print; exit}' "$HOME/chaindata/namada-1/$CHAIN_ID/wallet.toml")


# to get our $DOMAIN
source $HOME/campfire.env

# write env file
env_file=$HOME/namada-interface/apps/faucet/.env
{

    # # for main branch:
    echo "NAMADA_INTERFACE_FAUCET_API_URL=https://api.faucet.$DOMAIN"
    echo "NAMADA_INTERFACE_FAUCET_API_ENDPOINT=/api/v1/faucet"
    echo "NAMADA_INTERFACE_FAUCET_LIMIT=1000"
    echo "NAMADA_INTERFACE_PROXY_PORT=9000"
    echo "NAMADA_INTERFACE_NAMADA_TOKEN=$NAM"

    # as documented in: namada-campfire/docker/container-build/faucet-frontend/README.md
    # echo "REACT_APP_FAUCET_API_URL=https://api.faucet.$DOMAIN"
    # echo "REACT_APP_FAUCET_API_ENDPOINT=/api/v1/faucet"
    # echo "REACT_APP_FAUCET_LIMIT=1000"
    # echo "REACT_APP_TOKEN_NAM=$NAM"

} > "$env_file"


# source the env before building
source $env_file

# Tear down any conatiners, remove them and their images
docker stop $(docker container ls --all | grep 'faucet-fe' | awk '{print $1}')
docker container rm --force $(docker container ls --all | grep 'faucet-fe' | awk '{print $1}')
if [ -z "${LOGS_NOFOLLOW}" ]; then
    docker image rm --force $(docker image ls --all | grep 'faucet-fe' | awk '{print $3}')
fi

# Build
cd $HOME/namada-interface
docker build -t faucet-fe:local .


# Start the faucet frontend
cd $HOME/namada-interface
docker run --name faucet-fe -d -p "4000:80" faucet-fe:local


if [ -z "${LOGS_NOFOLLOW}" ]; then
    echo "**************************************************************************************"
    echo "Following faucet frontend logs, feel free to press Ctrl+C to exit!"
    docker logs -f $(docker container ls --all | grep faucet-fe | awk '{print $1}')
fi
