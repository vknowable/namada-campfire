## namada-interface
1. clone the repo: `git clone https://github.com/anoma/namada-interface.git`
2. copy the Dockerfile and nginx.conf files into the repo root folder
3. create or update the file `apps/namada-interface/.env` with the appropriate info (only the 'NAMADA' section is required):
```
# NAMADA
NAMADA_INTERFACE_NAMADA_ALIAS=Namada Testnet
NAMADA_INTERFACE_NAMADA_TOKEN=tnam1q87wtaqqtlwkw927gaff34hgda36huk0kgry692a
NAMADA_INTERFACE_NAMADA_CHAIN_ID=<chain id here>
NAMADA_INTERFACE_NAMADA_URL=https://rpc.knowable.run
NAMADA_INTERFACE_NAMADA_BECH32_PREFIX=tnam
```
4. build the container (run this from the project root): `docker build -t interface:local .`
5. run the container: `docker run --name interface -d -p "3000:80" interface:local`