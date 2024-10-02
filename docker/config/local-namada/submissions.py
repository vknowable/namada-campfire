import toml

# read the contents of /root/namada-campfire/docker/config/local-namada/genesis/balances.toml.new and write populate a list that work work with the following code:# uncomment this if you want to add pregenesis validators to submissions.py
# for index, val in enumerate(validator_array):
#   key = f"val-{index}"
#   balances_config[key] = {
#     'pk': val[0],
#     'address': val[1]
#   }

# this is what the content of balances.toml.new looks like:
# # source: https://raw.githubusercontent.com/anoma/namada-genesis/refs/heads/main/balances.toml
# [token.NAM]

# tnam1qxdzup2hcvhswcgw5kerd5lfkf04t64y3scgqm5v = "55270111.750000" # (categories: ['public_allocations_future']) (name: Luminara)
# tnam1q8nm4ar7aua8035du0m8x6amfe4407uzvqtfs6lm = "50000000.000000" # (categories: ['r&d_ecosystem_dev']) (name: Anoma Foundation)
# tnam1qxt7uxhj9r00mfm4u870e7ghz6j20jrdz58gm5kj = "36846674.523594" # (categories: ['public_allocations_future']) (name: Anoma Foundation)

# the validator_array should be able to be imported and iterated over


class ValidatorArray(list):
    def __init__(self):
        super().__init__()
        with open("/genesis/balances.toml.new", "r") as f:
            balances_toml = toml.load(f)
            for token in balances_toml:
                for address, amount in balances_toml[token].items():
                    self.append((address, amount))


# Create an instance
validator_array = ValidatorArray()
