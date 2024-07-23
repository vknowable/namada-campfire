#!/usr/bin/env python3
import sys
import toml
import os
import re
from submissions import validator_array

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
      else:
        balances_config[alias] = {
          'pk': transactions_toml['established_account'][0]['public_keys'][0],
        }

#for index, pk in enumerate(pk_array):
#  key = f"alum-{index}"
#  balances_config[key] = {
#    'pk': pk
#  }

#validator_array = [
#["tpknam1qzwqar4rydp4nsn4j2xj8hef8jknh3dv7dv99snqd5lfkj8p4pa2vny7cph", "tnam1q9tguf7ppxudvgjpkl5u80el28kyhdxhtspk26hl"], # s4
#["tpknam1qp87s56pfekaukvs0ernayr7plt4a673sj9pfc7wuj26nsrw567jjfwcx2c", "tnam1qyjjdxmdgnr6r68d6zsacevv27cxy3np8qv8zm2z"], # s3
#]

for index, val in enumerate(validator_array):
  key = f"val-{index}"
  balances_config[key] = {
    'pk': val[0],
    'address': val[1]
  }

############## NEW WAY ##############
#ACCOUNT_AMOUNT = "1000000000"
#USER_AMOUNT = "10000"
#FAUCET_AMOUNT = "8123372036854000000"

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
                output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['FAUCET_AMOUNT']   # FAUCET_AMOUNT
            elif entry == 'steward-1':
                output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT']  # ACCOUNT_AMOUNT
#            elif 'alum' in entry:
#                output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['USER_AMOUNT']       # USER_AMOUNT
            elif 'val' in entry:
                if 'NAM' in token:
                    if output_toml.get('token', {}).get(token, {}).get(balances_config[entry].get('pk')) is not None:
                        output_toml['token'][token][balances_config[entry]['address']] = output_toml['token'][token][balances_config[entry]['pk']]
                    else:
                        output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT
                        output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT

#                    if pk in pk_array:
#                        output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['USER_AMOUNT'] # VAL_AMOUNT
#                        output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['USER_AMOUNT'] # VAL_AMOUNT
#                    else:
#                        output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT
#                        output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['VAL_AMOUNT'] # VAL_AMOUNT

            # namada-x validators
            else:
                if 'NAM' in token:
                    output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
                    output_toml['token'][token][balances_config[entry]['address']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
                else:
                    output_toml['token'][token][balances_config[entry]['pk']] = TOKEN_ALLOCATIONS[token_key]['ACCOUNT_AMOUNT'] # ACCOUNT_AMOUNT
    return output_toml


output_toml = toml.load(balances_toml)
output_toml = distribute_balances(output_toml, balances_config)


# ############## OLD WAY ##############
# output_toml = toml.load(balances_toml)
# ACCOUNT_AMOUNT = "1000000000"
# USER_AMOUNT = "10000"
# FAUCET_AMOUNT = "8123372036854000000"

# for entry in balances_config:
#   for token in output_toml['token']:
#     if entry == 'faucet-1':
#       output_toml['token'][token][balances_config[entry]['pk']] = FAUCET_AMOUNT
#     elif entry == 'steward-1':
#       output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT
#     elif 'alum' in entry:
#       output_toml['token'][token][balances_config[entry]['pk']] = USER_AMOUNT
#     else:
#       if 'NAM' in token:
#         output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT
#         output_toml['token'][token][balances_config[entry]['address']] = ACCOUNT_AMOUNT
#       else:
#         output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT
# ############## OLD WAY ##############


print(toml.dumps(output_toml))
