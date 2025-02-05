#!/bin/bash

set -e

python3 config-generator.py
python3 add-keys.py

if [ "$ONLY_CREATE_CHANNEL" = "true" ]
then
    echo "Creating a new channel"

    hermes --config config.toml create channel \
        --a-chain "$NAMADA_CHAIN_ID" \
        --b-chain "$OTHER_CHAIN_ID" \
        --a-port transfer \
        --b-port transfer \
        --new-client-connection --yes
else
    echo "Not creating a new channel"

    echo "Validating config..."
    hermes --config config.toml config validate

    echo "Running health check..."
    hermes --config config.toml health-check

    echo "Starting!"
    hermes --config config.toml start
fi