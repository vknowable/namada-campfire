#!/bin/bash

# uncomment this line for script debugging
# set -x

# TODO: set chain-prefix by env var

namada --version

#apt install expect -y  # namadaw key gen doesn't seem to have non-interactive option yet

# clean up the http server when the script exits
cleanup() {
    pkill -f "/serve"
}

#tail -f /dev/null
export PUBLIC_IP=$(ip a | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2} brd ([0-9]{1,3}\.){3}[0-9]{1,3}' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d '/' -f1)
export ALIAS=$(hostname)

if [ ! -f "/root/.namada-shared/chain.config" ]; then
  # generate key
  namadaw --pre-genesis gen --alias $ALIAS --unsafe-dont-encrypt
  # create established account
  est_output=$(namadac utils init-genesis-established-account --aliases $ALIAS --path /root/.local/share/namada/pre-genesis/unsigned-transactions.toml)
  echo $est_output

  EST_ADDRESS=$(echo $est_output | grep -o 'tnam[[:alnum:]]*')
  # promote established account to validator
  namadac utils init-genesis-validator \
    --alias $ALIAS \
    --address $EST_ADDRESS \
    --path "/root/.local/share/namada/pre-genesis/unsigned-transactions.toml" \
    --net-address "${PUBLIC_IP}:26656" \
    --commission-rate 0.05 \
    --max-commission-rate-change 0.01 \
    --email "$ALIAS@namada.net" \
    --description "The $ALIAS validator." \
    --website "http://$ALIAS.io" \
    --discord-handle "$ALIAS" \
    --self-bond-amount 10000000 \
    --unsafe-dont-encrypt

  mkdir -p /root/.namada-shared/$ALIAS
  # sign genesis transactions
  namadac utils sign-genesis-txs \
    --path "/root/.local/share/namada/pre-genesis/unsigned-transactions.toml" \
    --output "/root/.namada-shared/$ALIAS/transactions.toml" \
    --alias $ALIAS
fi

############  generating chain configs, done on host namada-1 only ############
if [ $(hostname) = "namada-1" ]; then

  if [ ! -f "/root/.namada-shared/chain.config" ]; then
    # wait until all validator configs have been written
    while [ ! -d "/root/.namada-shared/namada-1" ] || [ ! -d "/root/.namada-shared/namada-2" ] || [ ! -d "/root/.namada-shared/namada-3" ]; do
      echo "Validator configs not ready. Sleeping for 5s..."
      sleep 5
    done

    echo "Validator configs found. Generating chain configs..."

    # create a pgf steward account with alias 'steward-1' and generate signed toml
    STEWARD_ALIAS="steward-1"
    namadaw --pre-genesis gen --alias $STEWARD_ALIAS --unsafe-dont-encrypt
    mkdir /root/.namada-shared/$STEWARD_ALIAS
    est_output=$(namadac utils init-genesis-established-account \
      --path "/root/.namada-shared/$STEWARD_ALIAS/unsigned-transactions.toml" \
      --aliases $STEWARD_ALIAS)
    echo $est_output
    steward_address=$(echo $est_output | grep -o 'tnam[[:alnum:]]*')
    namadac utils sign-genesis-txs \
      --path "/root/.namada-shared/$STEWARD_ALIAS/unsigned-transactions.toml" \
      --output "/root/.namada-shared/$STEWARD_ALIAS/transactions.toml"
    rm -rf /root/.namada-shared/$STEWARD_ALIAS/unsigned-transactions.toml

    # create a faucet account and signed-toml
    FAUCET_ALIAS="faucet-1"
    namadaw --pre-genesis gen --alias $FAUCET_ALIAS --unsafe-dont-encrypt
    mkdir -p /root/.namada-shared/$FAUCET_ALIAS
    est_output=$(namadac utils init-genesis-established-account \
      --path "/root/.namada-shared/$FAUCET_ALIAS/unsigned-transactions.toml" \
      --aliases $FAUCET_ALIAS)
    echo $est_output
    faucet_address=$(echo $est_output | grep -o 'tnam[[:alnum:]]*')
    namadac utils sign-genesis-txs \
      --path "/root/.namada-shared/$FAUCET_ALIAS/unsigned-transactions.toml" \
      --output "/root/.namada-shared/$FAUCET_ALIAS/transactions.toml"
    rm -rf /root/.namada-shared/$FAUCET_ALIAS/unsigned-transactions.toml

    # create directory for genesis toml files
    mkdir -p /root/.namada-shared/genesis
    cp /genesis/parameters.toml /root/.namada-shared/genesis/parameters.toml
    cp /genesis/tokens.toml /root/.namada-shared/genesis/tokens.toml
    cp /genesis/validity-predicates.toml /root/.namada-shared/genesis/validity-predicates.toml
    cp /genesis/transactions.toml /root/.namada-shared/genesis/transactions.toml

    # add genesis transactions to transactions.toml
    # TODO: move to python script
    cat /root/.namada-shared/namada-1/transactions.toml >> /root/.namada-shared/genesis/transactions.toml
    cat /root/.namada-shared/namada-2/transactions.toml >> /root/.namada-shared/genesis/transactions.toml
    cat /root/.namada-shared/namada-3/transactions.toml >> /root/.namada-shared/genesis/transactions.toml
    cat /root/.namada-shared/$STEWARD_ALIAS/transactions.toml >> /root/.namada-shared/genesis/transactions.toml
    cat /root/.namada-shared/$FAUCET_ALIAS/transactions.toml >> /root/.namada-shared/genesis/transactions.toml

    python3 /scripts/make_balances.py /root/.namada-shared /genesis/balances.toml > /root/.namada-shared/genesis/balances.toml

    # add steward address to parameters.toml
    sed -i "s#STEWARD_ADDR#$steward_address#g" /root/.namada-shared/genesis/parameters.toml

    INIT_OUTPUT=$(namadac utils init-network \
      --genesis-time "2023-11-13T00:00:00Z" \
      --wasm-checksums-path /wasm/checksums.json \
      --chain-prefix $CHAIN_PREFIX \
      --templates-path /root/.namada-shared/genesis \
      --consensus-timeout-commit 10s)

    echo "$INIT_OUTPUT"
    CHAIN_ID=$(echo "$INIT_OUTPUT" \
      | grep 'Derived chain ID:' \
      | awk '{print $4}')
    echo "Chain id: $CHAIN_ID"
  fi

  # serve config tar over http
  echo "Serving configs..."
  mkdir -p /serve
  cp *.tar.gz /serve
  trap cleanup EXIT
  nohup bash -c "python3 -m http.server --directory /serve 8123 &"

  if [ ! -f "/root/.namada-shared/chain.config" ]; then
    # write config server info to shared volume
    sleep 2
    printf "%b\n%b" "$PUBLIC_IP" "$CHAIN_ID" | tee /root/.namada-shared/chain.config
  fi

### end namada-1 specific prep ###

### other nodes should pause here until chain configs are ready ###
else
  while [ ! -f "/root/.namada-shared/chain.config" ]; do
    echo "Configs server info not ready. Sleeping for 5s..."
    sleep 5
  done

  echo "Configs server info found, proceeding with network setup"
fi

############ all nodes resume here ############

# one last sleep to make sure configs server has been given time to start
sleep 5

# get chain config server info
CONFIG_IP=$(awk 'NR==1' /root/.namada-shared/chain.config)
export CHAIN_ID=$(awk 'NR==2' /root/.namada-shared/chain.config)
export NAMADA_NETWORK_CONFIGS_SERVER="http://${CONFIG_IP}:8123"
curl $NAMADA_NETWORK_CONFIGS_SERVER
rm -rf /root/.local/share/namada/$CHAIN_ID
namada client utils join-network \
  --chain-id $CHAIN_ID --genesis-validator $ALIAS --dont-prefetch-wasm

# copy wasm to namada dir
cp -a /wasm/*.wasm /root/.local/share/namada/$CHAIN_ID/wasm
cp -a /wasm/checksums.json /root/.local/share/namada/$CHAIN_ID/wasm

# configure namada-1 node to advertise host public ip to outside peers if provided
EXTIP=${EXTIP:-''}
if [ -n "$EXTIP" ]; then
echo "Advertising public ip $EXTIP"
  sed -i "s#external_address = \".*\"#external_address = \"$EXTIP:${P2P_PORT:-26656}\"#g" /root/.local/share/namada/$CHAIN_ID/config.toml
  ## modified for public facing nginx
  namada node ledger run-until --block-height 0 --halt
  NODE_ID=$(cometbft show-node-id --home ~/.local/share/namada/$CHAIN_ID/cometbft/ | awk '{last_line = $0} END {print last_line}')
  rm -f /output/*.tar.gz
  cp /*.tar.gz /output
  # Write content to luminara.env
  CONFIGS_SERVER="http://${EXTIP}:${SERVE_PORT}"
  PEERS="\"tcp://$NODE_ID@${EXTIP}:${P2P_PORT:-26656}\""
  echo "CHAIN_ID=$CHAIN_ID" > /luminara.env
  echo "#EXTIP=" >> /luminara.env
  echo "CONFIGS_SERVER=https://testnet.luminara.icu/configs" >> /luminara.env
  echo "PERSISTENT_PEERS=$PEERS" >> /luminara.env
  rm -f /output/luminara.env
  cp /luminara.env /output/luminara.env
  cp /index.html /output/index.html
  sed -i "s/CHAIN_ID/$CHAIN_ID/g" /output/index.html
  sed -i "s/NAMADA_TAG/$NAMADA_TAG/g" /output/index.html
  sed -i "s/DOMAIN/$DOMAIN/g" /output/index.html
  sed -i "s/CHAIN_PREFIX/$CHAIN_PREFIX/g" /output/index.html
  tar -czvf /output/wasm.tar.gz /wasm
  ##
fi

# allow rpc connections on namada-3 node
if [ $(hostname) = "namada-3" ]; then
  sed -i "s#laddr = \"tcp://.*:26657\"#laddr = \"tcp://0.0.0.0:26657\"#g" /root/.local/share/namada/$CHAIN_ID/config.toml
  sed -i "s#cors_allowed_origins = .*#cors_allowed_origins = [\"*\"]#g" /root/.local/share/namada/$CHAIN_ID/config.toml
  sed -i "s#prometheus = .*#prometheus = true#g" /root/.local/share/namada/$CHAIN_ID/config.toml
  sed -i "s#namespace = .*#namespace = \"tendermint\"#g" /root/.local/share/namada/$CHAIN_ID/config.toml
fi

# start node
RUST_BACKTRACE=1 NAMADA_LOG=info CMT_LOG_LEVEL=p2p:none,pex:error NAMADA_CMT_STDOUT=true namada node ledger run

# this line is for debug purposes;
# if the namada process panics (eg: consensus error), this will keep the container paused indefinitely so that we
# can grab any logs, files etc needed for debugging before restarting the network
tail -f /dev/null