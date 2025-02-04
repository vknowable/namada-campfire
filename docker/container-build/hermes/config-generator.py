import os
from string import Template


def main():
    data = {
        'namada_chain_id': os.environ.get("NAMADA_CHAIN_ID"),
        'namada_rpc': os.environ.get("NAMADA_RPC"),
        'namada_ws': os.environ.get("NAMADA_WS"),
        'namada_key_id': os.environ.get("NAMADA_KEY_ID"),
        'namada_trusting_period': os.environ.get("NAMADA_TRUSTING_PERIOD", '550s'),
        'namada_denomination': os.environ.get("NAMADA_DENOMINATION"),
        'namada_memo': os.environ.get("NAMADA_MEMO"),
        'other_chain_id': os.environ.get("OTHER_CHAIN_ID"),
        'other_rpc': os.environ.get("OTHER_RPC"),
        'other_ws': os.environ.get("OTHER_WS"),
        'other_grpc': os.environ.get("OTHER_GRPC"),
        'other_account_prefix': os.environ.get("OTHER_ACCOUNT_PREFIX"),
        'other_denomination': os.environ.get("OTHER_DENOMINATION"),
        'other_memo': os.environ.get("OTHER_MEMO"),
        'other_key_id': os.environ.get("OTHER_KEY_ID"),
        'other_trusting_period': os.environ.get("OTHER_TRUSTING_PERIOD", '172700s'),
        'namada_filter': '[]' if os.environ.get("NAMADA_FILTER") is None else "[['transfer', '{}']]".format(os.environ.get("NAMADA_FILTER")),
        'other_filter': '[]' if os.environ.get("OTHER_FILTER") is None else "[['transfer', '{}']]".format(os.environ.get("OTHER_FILTER")),
        'namada_policy': 'deny' if os.environ.get("NAMADA_FILTER") is None else 'allow',
        'other_policy': 'deny' if os.environ.get("OTHER_FILTER") is None else 'allow'
    }

    all_valid = True
    for field in data.keys():
        if not data[field]:
            all_valid = False
            print("'{}' is not defined!".format(field))
        else:
            print("'{}' is valid.".format(field))
    
    if not all_valid:
        exit(1)

    with open('config-template.toml.template', 'r') as f:
        config = Template(f.read())
        result = config.substitute(data)
        print(result)
        with open("config.toml", "w") as f:
            f.write(result)

if __name__ == '__main__':
    main()