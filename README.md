# Namada "Campfire" Testnet Hosting Resources

### Recommended Installs
- (required) Docker/Compose (there is an install script to install Docker and a few other misc dependencies in the `scripts` folder). If you are a non-root user, you will want to add yourself to the 'docker' group so that you can run docker commands without sudo (to ensure scripts work as intended without stopping to prompt for a password)
- Nginx to proxy to landing page, rpc, faucet etc (example nginx config in `config` folder)
- LetsEncrypt/Certbot for SSL certificates
- Any other general security practices (eg: Fail2Ban, SSH 2fa)

### Prep
1. Provision a domain name -- we'll use knowable.run as an example. Setup your DNS records to point to your server, along with any corresponding subdomains. For a setup that includes chain, landing page, rpc, and faucet we can setup these records:  
`knowable.run testnet.knowable.run faucet.knowable.run api.faucet.knowable.run rpc.knowable.run`  
This scheme can be extended to add additional subdomains for other components (for example `interface.knowable.run` etc.)
2. Clone this repo onto your server.
3. Install some dependencies:  
Docker/Compose: `scripts/install-docker.sh`  
Nginx: `sudo apt install nginx`  
LetsEncrypt/Certbot: `sudo apt install certbot python3-certbot-nginx`  
4. Obtain your SSL certs: `sudo certbot --nginx -d knowable.run -d testnet.knowable.run -d faucet.knowable.run -d api.faucet.knowable.run -d rpc.knowable.run --register-unsafely-without-email --agree-tos`  
Take note of the location where they're saved, for eg:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/knowable.run/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/knowable.run/privkey.pem
```
5. Replace the default nginx config at `/etc/nginx/sites-enabled/default` with the contents of `config/nginx.conf` (modifying paths, domain names, ports etc as needed). Be sure to restart the nginx service after changing the config.
6. Create a textfile (in any location you like) for the env variables used to configure the Campfire chain, following the example in `config/campfire.env`
7. Build the containers for Namada, Faucet-frontend and Faucet-backend following the instructions in `docker/container-build` directory. Verify the images were built correctly:
```
# docker image ls
REPOSITORY    TAG       IMAGE ID       CREATED             SIZE
faucet-be     local     c23a96aad4bb   24 minutes ago      125MB
faucet-fe     local     0ee44868743f   54 minutes ago      70.7MB
namada        v0.35.1   5cfbccd74f18   About an hour ago   573MB
```

### Starting the chain
You can launch the chain by running the script `scripts/relaunch.sh`, or by following these steps:  

1. Before starting, check the docker compose file `docker/compose/docker-compose-local-namada.yml` and make sure the paths for each volume point to a sensible location on your server. (Change them if needed).
2. Start the chain using the compose file and the env file you created in the previous section:  
```
# first set this to specify which container image to use, ie: namada:${NAMADA_TAG}
export NAMADA_TAG=v0.35.1
docker compose -f ~/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file ~/campfire.env up -d
```
3. After the chain has started, you can obtain the chain-id, faucet private-key and NAM token address (both found in the wallet.toml of the namada-1 node `~/chaindata/namada-1/$CHAIN_ID/wallet.toml`). You can now start the faucet backend:  
`docker run --name faucet-be -d -p "5000:5000" faucet-be:local ./server --cargo-env development --difficulty 3 --private-key $FAUCET_PK --chain-start 1 --chain-id $CHAIN_ID --port 5000 --rps 10  --rpc http://172.17.0.1:26657`  
and frontend:  
`docker run --name faucet-fe -d -p "4000:80" faucet-fe:local`  

(Note: the NAM token address is assumed to be `tnam1q87wtaqqtlwkw927gaff34hgda36huk0kgry692a` but if yours if different for some reason, you will have to update the faucet-frontend env file `~/namada-interface/apps/faucet/.env` with the new value and rebuild the frontend container to incorporate the changes.)  

You can test that everything is working by creating a test address and requesting some tokens from the faucet:  
```
docker exec -it compose-namada-1-1 /bin/bash
namadaw gen --alias test --unsafe-dont-encrypt
namadaw list # note your tnam address

# go to https://faucet.knowable.run in your web browser and request some tokens

namadac balance --owner test
# you should see your tokens
```

### Upgrading the chain
You can re-launch the chain by running the script `scripts/relaunch.sh`, or follow these steps to stop the chain, wipe all chain data, and re-launch with a different version of Namada:  

1. Build the container image for the new version of Namada (this can be done while the old chain is still running, to minimize downtime). There shouldn't be any need to rebuild the faucet frontend or backend containers in most cases.
2. Stop the chain: `docker compose -f ~/namada-campfire/docker/compose/docker-compose-local-namada.yml --env-file ~/campfire.env down --volumes`
3. Delete the old chain data from disk: `sudo rm -rf ~/chaindata`
4. Stop and remove the two faucet containers: `docker stop faucet-fe faucet-be && docker rm faucet-fe faucet-be`
5. Build the container image for the new version of Namada. There shouldn't be any need to rebuild the faucet frontend or backend containers in most cases.
6. Relaunch the chain according to the steps in **Starting the chain**.  

Sometimes, a new version of Namada will require changes to the node startup script, genesis parameter toml files, or faucet source code. These will need to be figured out as needed through trial and error.