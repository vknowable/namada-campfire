## faucet front-end

1. clone repo https://github.com/anoma/namada-interface.git
2. the front-end was changed for the shielded-expedition to work with the extension and the shielded-expedition chain parameters. Therefore, we'll checkout a version prior to the changes (more recent commits may also work but this one is tested): `git checkout v0.1.0-0e77e71`
3. place `Dockerfile` in repo root
4. in the folder `{repo root}/apps/faucet` create a new folder named `docker` and place `nginx.conf` inside
5. we will also need to create the file `{repo root}/apps/faucet/.env` with the following content (modify according to your domain and the NAM token address of your chain). The NAM token address can be found by checking the wallet.toml of any node, but will likely be the same as the one listed here. 
```
# Faucet API Endpoint override
REACT_APP_FAUCET_API_URL=https://api.faucet.knowable.run
REACT_APP_FAUCET_API_ENDPOINT=/api/v1/faucet

# Faucet limit, as defined in genesis toml
REACT_APP_FAUCET_LIMIT=1000

# Override default token addresses
REACT_APP_TOKEN_NAM=tnam1q87wtaqqtlwkw927gaff34hgda36huk0kgry692a
```
6. build container: `docker build -t faucet-fe:local .`
7. run:  
`docker run --name faucet-fe -d -p "4000:80" faucet-fe:local`