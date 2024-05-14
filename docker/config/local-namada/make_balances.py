#!/usr/bin/env python3
import sys
import toml
import os
import re

validator_directory = sys.argv[1]
balances_toml = sys.argv[2]

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
      if 'namada' in alias:
        balances_config[alias] = {
          'pk': transactions_toml['established_account'][0]['public_keys'][0],
          'address': transactions_toml['validator_account'][0]['address']
        }
      else:
        balances_config[alias] = {
          'pk': transactions_toml['established_account'][0]['public_keys'][0],
        }

##############
pk_array = ["tpknam1qqzqwx0pqr3uz3krq7vzgjg803tksgrsul4xztjtwe02zyk2mn4c20cp256",
"tpknam1qz2ma7q2jf35jetnjylkjsve4ztjl0cczl5p7cvccsusfvsa7syp6szz29j",
"tpknam1qpj9cdq7zc7sful4m3ag046k0r69dnh5ldq9d4ws9s0mw6wklhduzejh9l2",
"tpknam1qzhf8dd36cxp9u8yxrkzggds50x7w7rldkn6a2u0ur2wq00kamr7zq8sjx8",
"tpknam1qq96puke5mcmq8zfe0ljkfqr3t9wlvha6wv8v7lw5v0rdvmefvf7v926pyd",
"tpknam1qz29rpa2ut05jq4ac9v0kwgan5udz8ca3drq06azsccr572zuxc7x70rjm3",
"tpknam1qqax33sajhgk4yxnm8fqenveuhfuwvtwzz09v8lnqpyah75eapj5stnzjkk",
"tpknam1qq6qx3clu29a6tua2gkmp836052rk90q2wr6fcahu27827weahwwvupfqmf",
"tpknam1qpmlecgcw9zz5qvx8xl72ds9tgewvwe7ls90csr6g9lupzcfcexlsphv3dx",
"tpknam1qzpt8hzamj4d8fddx80gu3zfnkgdvxh4etpy5ny4m66u657kuj385n4zs8v",
"tpknam1qpega8pyy48nf8yx6s8mz93gud68euze3ytvw9knxvx23t0kk8agktpjmfn",
"tpknam1qq6229yc0yxeugm05u09afnmv8lj2vlnr5gsfrj2hurp483plwne7e667sz",
"tpknam1qq2ae34hhs90de57e7w2gr248k9knaddda5x3yukl8c5m9luh72rz2lftnc",
"tpknam1qqux9h6afvmuwvk6wruu9nxf27mv8ev7ku6z556z8wn3arvsqc5xcwz50nj",
"tpknam1qzgtwnf6jay3msjn6pkytqn88kdynq0gs624pm9uxz76ezdu2wvw25rjs5l",
"tpknam1qzdw5d353w0y3rfc2xueureq2ytjakfsa9qmyhu99tzuwpd6ypv3x50su0g",
"tpknam1qpt800qnz9jrmh6lt0uh6cl6scrmnhpasn0dew0yen65clm9yvlm2ym6j5w",
"tpknam1qq990vh6gnkvvxkx8ds4gphnzymkjqtysaqdwcsvsy2rhc42sac8wwkzwr6",
"tpknam1qqjdk64qsv9v3etk5h9dxqq9r3hr06tul4j4mjpwg9mxa4fk2klz585fujy",
"tpknam1qz7ludn97kr00j0a2na04w9c69p25mcul4y3h9npxlhr83rqddcn60hjv0d",
"tpknam1qz8m7ud7ge0eudtrhkm8gxhh807szwnj6kqxckqda4mdwuhxpqfvyp2l2m5",
"tpknam1qz0hj9w3gr9fnzttaur87hxuxjqpztyq0tnpum5v0xe5sqrf2cs6jh5l9un",
"tpknam1qzw8crz2mhuaaekr9v3uc22pyumh6g9fzeqhkg8thjjrcmp86sx7zaf0ekv",
"tpknam1qzjxrp8s2pkwpuylwalnsv8nreyftcr09k4cvdxyn0vjaa80y9stwyew4ac",
"tpknam1qp6nc4qj64queu3jgzs4tc9a0dk42yhjhjacajxeev8672tndznu5g2jk68",
"tpknam1qrzzt6qa4207summvat2z2rg3kfm5n5srf5uvdn52a5yc9jp97xejcu7ewl",
"tpknam1qpjq335qukvktl7wt092aucmaamv0xhqjhchxawuxsrfqyasp0zg2hmpqp3",
"tpknam1qqh97qe7q6ykve3h5rznvpq5w8x8wc4e2a4vqeua59v0afguahkl7zjdhyp",
"tpknam1qqtdjyc6r44lxm0fmwv2sv8tv3zpd4ujpjaatnvp2hwa4j6esteuwke47hs"]

for index, pk in enumerate(pk_array):
  key = f"alum-{index}"
  balances_config[key] = {
    'pk': pk
  }
##############
output_toml = toml.load(balances_toml)
ACCOUNT_AMOUNT = "1000000000"
USER_AMOUNT = "10000"
FAUCET_AMOUNT = "8123372036854000000"

for entry in balances_config:
  for token in output_toml['token']:
    if entry == 'faucet-1':
      output_toml['token'][token][balances_config[entry]['pk']] = FAUCET_AMOUNT
    elif entry == 'steward-1':
      output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT
    elif 'alum' in entry:
      output_toml['token'][token][balances_config[entry]['pk']] = USER_AMOUNT
    else:
      if 'NAM' in token:
        output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT
        output_toml['token'][token][balances_config[entry]['address']] = ACCOUNT_AMOUNT
      else:
        output_toml['token'][token][balances_config[entry]['pk']] = ACCOUNT_AMOUNT


print(toml.dumps(output_toml))
