# Hermes relayer

A simpler way to run a namada relayer.

## How to run

1) docker build .
2) docker run 
    ```
    docker run -it --rm \
    -e NAMADA_CHAIN_ID=$NAMADA_CHAIN_ID \
    -e NAMADA_RPC=$NAMADA_RPC \
    -e NAMADA_WS=$NAMADA_WS \
    -e NAMADA_KEY_ID=$NAMADA_HERMES_KEY_NAME \
    -e NAMADA_DENOMINATION=$NAMADA_FEE_TOKEN \
    -e NAMADA_MEMO=$NAMADA_MEMO \
    -e OTHER_CHAIN_ID=$COUNTERPARTY_CHAIN_ID \
    -e OTHER_RPC=$COUNTERPARTY_RPC \
    -e OTHER_WS=$COUNTERPARTY_WS \
    -e OTHER_GRPC='$COUNTERPARTY_GRPC \
    -e OTHER_ACCOUNT_PREFIX=$COUNTERPARTY_PREFIX \
    -e OTHER_DENOMINATION=$COUNTERPARTY_DENOMINATION \
    -e OTHER_MEMO=COUNTERPARTY_MEMO \
    -e NAMADA_TRUSTING_PERIOD=COUNTERPARTY_TRUSTING_PERIOD \
    -e OTHER_KEY_ID=COUNTERPARTY_KEY_ID \
    -e NAMADA_FILTER='channel-X' \
    -e OTHER_FILTER='channel-X' \
    -e ONLY_CREATE_CHANNEL='true/false' \
    -v ${PWD}/keys:/app/keys:ro \
    -p 3005:3005 \ # only needed if you want to enable apis
    -p 3000:3000 \
    f1868f559fb6
    ```
