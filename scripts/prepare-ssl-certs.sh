#!/usr/bin/env bash


echo "**************************************************************************************"
echo "Updating nginx-full"
echo "**************************************************************************************"
sudo apt -y update
sudo apt -y upgrade nginx-full


echo "**************************************************************************************"
echo "Obtaining SSL certificates for Namada Campfire structure"
echo "**************************************************************************************"


# Prepare for domain
if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "This script assumes you have provisioned a domain name and pointed your DNS"
  echo "records for testnet/faucet/api/rpc/interface subdomains to this server (wildcards work)"
  echo "and have run ./scripts/install-dependencies.sh script ahead of time."
  echo "Only proceed if you are sure you have this ready."
  echo "**************************************************************************************"
  read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Provide the TLD
read -p "Enter your top level domain name (ex. knowable.run): " TLD_NAME
export TLD_NAME=$TLD_NAME


# Prepare for firewall and 
if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "This script will attept to use UFW to open TCP ports 80 and 443, obtain an SSL, and"
  echo "configure nginx for Campfire testnet/faucet/api/rpc/interface subdomains on this server."
  echo "Only proceed if you are sure you have this ready."
  echo "**************************************************************************************"
  read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Open ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp


# remove default nginx config
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default

# copy ~/namada-campfire/config/nginx-vanilla.conf to /etc/nginx/sites-available/default
sudo cp -f ~/namada-campfire/config/nginx-vanilla.conf /etc/nginx/sites-available/default

# change all instances of 'TLD_NAME' in config to $TLD_NAME
sudo sed -i "s/TLD_NAME/$TLD_NAME/g" /etc/nginx/sites-available/default

# create symbolic link
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# test config
sudo nginx -t

# reload nginx
sudo systemctl reload nginx


# Fetching the certificates
sudo certbot --nginx -d $TLD_NAME -d testnet.$TLD_NAME -d faucet.$TLD_NAME -d api.faucet.$TLD_NAME -d rpc.$TLD_NAME -d interface.$TLD_NAME -d indexer.$TLD_NAME -d explorer.$TLD_NAME --register-unsafely-without-email --agree-tos
