#!/bin/bash

# URL to check
URL="https://rpc.knowable.run"

# Command to run if the check fails
RESTART_COMMAND="docker restart compose-namada-2-1"

# Perform the check
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $URL)

# Check if the response is 502
if [ "$RESPONSE" == "502" ] || [ "$RESPONSE" == "000" ]; then
    $RESTART_COMMAND
fi
