#!/usr/bin/env python3
import sys
import toml
import os
import re
from submissions import validator_array
from genesis_accounts import genesis_account_array

validator_directory = sys.argv[1]
balances_toml = sys.argv[2]
self_bond_amount = sys.argv[3]

balances_config = {}

# iterate over each validator config in the base directory
for subdir in os.listdir(validator_directory):
  alias = subdir
  subdir_path = os.path.join(validator_directory, subdir)

  if os.path.isdir(subdir_path):
    toml_files = [f for f in os.listdir(subdir_path) if f.endswith(".toml")]
    if len(toml_files) == 1:
      toml_file_path = os.path.join(subdir_path, toml_files[0])
      transactions_toml = toml.load(toml_file_path)
      # namada-x validator balances
      if 'namada' in alias:
        balances_config[alias] = {
          'pk': transactions_toml['established_account'][0]['public_keys'][0],
          'address': transactions_toml['validator_account'][0]['address']
        }
      
# non-validator genesis implicit accounts (typically faucet and steward)
for index, account in enumerate(genesis_account_array):
  key = f"{account[0]}"
  balances_config[key] = {
    'alias': account[0],
    'address': account[1]
  }

# uncomment this if you want to add pregenesis validators to submissions.py
# for index, val in enumerate(validator_array):
#   key = f"val-{index}"
#   balances_config[key] = {
#     'pk': val[0],
#     'address': val[1]
#   }

# create an array that has a key for the token and a index for 'faucet-1', 'steward-1', 'alum-0', 'alum-1', etc.
# as of now there will be 32 accounts for each token in balances.toml
TOKEN_ALLOCATIONS = {
    'NAM': {
        'FAUCET_AMOUNT':  "499710000",            # FAUCET_AMOUNT
        'ACCOUNT_AMOUNT': f"{self_bond_amount}",  # ACCOUNT_AMOUNT
        'USER_AMOUNT':    "10000",                 # USER_AMOUNT
        'VAL_AMOUNT':     "1"
    },
    'BTC': {
        'FAUCET_AMOUNT':  "17710000",             # FAUCET_AMOUNT
        'ACCOUNT_AMOUNT': "1000000",              # ACCOUNT_AMOUNT
        'USER_AMOUNT':    "10000"                 # USER_AMOUNT
    },
    '___': {
        'FAUCET_AMOUNT':  "499710000",            # FAUCET_AMOUNT
        'ACCOUNT_AMOUNT': "100000000",            # ACCOUNT_AMOUNT
      'USER_AMOUNT':      "10000"                 # USER_AMOUNT
    }
}

def distribute_balances(output_toml, balances_config):
    for entry in balances_config:
        for token in output_toml['token']:
            if token in TOKEN_ALLOCATIONS:
                token_key = token
            else:
                token_key = '___'                

            if entry == 'faucet-1':
                output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['FAUCET_AMOUNT']   # FAUCET_AMOUNT
            elif entry == 'steward-1':
                output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT']  # ACCOUNT_AMOUNT

            elif 'val' in entry:
                if 'NAM' in token:
                    if output_toml.get('token', {}).get(token, {}).get(balances_config[entry].get('pk')) is not None:
                        output_toml['token'][token][balances_config[entry]['address']] = output_toml['token'][token][balances_config[entry]['pk']]
                    else:
                        output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT
                        output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT

            # namada-x validators
            else:
                if 'NAM' in token:
                    # output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
                    output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
                else:
                    # output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
                    output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
    return output_toml


output_toml = toml.load(balances_toml)
output_toml = distribute_balances(output_toml, balances_config)

print(toml.dumps(output_toml))
