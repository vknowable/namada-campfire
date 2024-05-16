## faucet-backend

1. clone repo https://github.com/heliaxdev/namada-faucet.git
2. the faucet was changed for the shielded-expedition incentivized testnet to check an api endpoint on a heliax server to see whether the requesting address was a registered shielded-expedition participant. The older versions are also not compatible with recent changes to the Namada Sdk. Therefore, we need to use this branch in a fork of the faucet that has been updated to work with Namada versions 0.35.1 and up:  
```
git clone https://github.com/vknowable/namada-faucet.git
git checkout campfire-faucet
```
3. place Dockerfile in the faucet repo root directory
4. cd into the faucet repo and build the container: `docker build -t faucet-be:local .`
5. start the faucet backend:  
`docker run --name faucet-be -d -p "5000:5000" faucet-be:local ./server --cargo-env devel
opment --difficulty 3 --private-key $FAUCET_PK --chain-start 1 --chain-id $CHAIN_ID --port 5000 --rps 10  --rpc http://172.17.0.1:26657`  
The faucet private key can be found inside the wallet.toml of the namada-1 node (by default, `~/chaindata/namada-1/$CHAIN_ID/wallet.toml`).  
Inside the wallet.toml, there will be an entry like this:  
```
[secret_keys]
faucet-1 = "unencrypted:00ffff81e5ef250bf430e56ca4c739b8be73db57783a479b9a0c554828e0da1af5"
```