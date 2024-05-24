#!/usr/bin/env bash

# First display a reasonable warning to the user unless run with -y
if ! [[ $# -eq 1 && $1 == "-y" ]]; then
  echo "**************************************************************************************"
  echo "This script requires sudo privilege. It *removes* any existing docker installed"
  echo "on this machine and then installs the latest docker release as well as other"
  echo "required packages."
  echo "Only proceed if you are sure you want to make those changes to this machine."
  echo "**************************************************************************************"
  read -p "Are you sure you want to proceed? " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# dismiss the popups
export DEBIAN_FRONTEND=noninteractive

## https://docs.docker.com/engine/install/ubuntu/
## https://superuser.com/questions/518859/ignore-packages-that-are-not-currently-installed-when-using-apt-get-remove1
packages_to_remove="docker docker-engine docker.io containerd runc"
installed_packages_to_remove=""
for package_to_remove in $(echo $packages_to_remove); do
  $(dpkg --info $package_to_remove &> /dev/null)
  if [[ $? -eq 0 ]]; then
    installed_packages_to_remove="$installed_packages_to_remove $package_to_remove"
  fi
done

# Enable stop on error now, since we needed it off for the code above
set -euo pipefail  ## https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/

if [[ -n "${installed_packages_to_remove}" ]]; then
  echo "**************************************************************************************"
  echo "Removing existing docker packages"
  sudo apt -y remove $installed_packages_to_remove
fi

echo "**************************************************************************************"
echo "Installing misc dependencies"
echo "**************************************************************************************"
sudo apt -y update

# install misc dependencies
sudo apt -y install jq git curl ca-certificates gnupg lz4

# Add dockerco package repository
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt -y update

echo "**************************************************************************************"
echo "Installing docker"
echo "**************************************************************************************"
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Allow the current user to use Docker
# you will likely still need to restart your session for the below to take effect
sudo usermod -aG docker $USER

echo "**************************************************************************************"
echo "Install complete"
echo "**************************************************************************************"
echo "Please log in again (docker will not work in this current shell) then:"
echo "test that docker is correctly installed and working for your user by running the"
echo "command below (it should print a message beginning \"Hello from Docker!\"):"
echo
echo "docker run hello-world"
echo
