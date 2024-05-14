## faucet front-end

1. clone repo https://github.com/anoma/namada-interface.git
2. `git checkout v0.2.0-24e9d1f`
3. place `Dockerfile` in repo root
4. in folder `{repo root}/apps/faucet` create a folder named `docker` and place `nginx.conf` inside
5. build container: `docker build -t faucet-fe:local .`
