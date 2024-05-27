## namadexer
1. clone the repo: `git clone https://github.com/Zondax/namadexer.git`
2. the repo already comes with a Dockerfile and Compose file which we can use to launch the indexer/database/json server containers. First, we need to provide the chain's `checksums.json` file and the `config/Settings.toml` config file:
- place the `checksums.json` file in the same directory as the compose file (`/contrib`)
- place the `Settings.toml` file in the `config` directory. For example:
```
log_level = "info"
log_format = "pretty"
# The chain name is the Chain ID value without what is after the '.' (e.g 'shielded-expedition.88f17d1d14' -> 'shielded-expedition')
chain_name = "tirefire"

[database]
host = "postgres"
user = "postgres"
password = "wow"
dbname = "blockchain"
port = 5432
# Optional field to configure a timeout if database connection
# fails.
connection_timeout = 20
create_index = true

[server]
serve_at = "0.0.0.0"
port = 30303
cors_allow_origins = []

[indexer]
tendermint_addr = "http://172.17.0.1:26657"

[jaeger]
enable = false
host = "localhost"
port = 6831

[prometheus]
host = "0.0.0.0"
port = 9000
```
3. start the containers using the compose file:
```
cd contrib
docker compose up -d
```