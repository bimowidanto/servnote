# Initial setup script for Ubuntu servers
Based on https://github.com/jasonheecs/ubuntu-server-setup with minor changes for Indonesian local repositoy

This is a setup script to automate the setup and provisioning of Ubuntu servers. It does the following:
* Change default repository to Indonesian Ubuntu Mirror
* Setup the timezone for the server (Default to "Asia/Jakarta")
* Update and upgrade server for first time
* Adds a new user account with sudo access
* Adds a public ssh key for the new user account
* Disables password authentication to the server
* Deny root login to the server
* Setup Uncomplicated Firewall
* Create Swap file based on machine's installed memory
* Install Network Time Protocol

# Installation
SSH into your server and install git if it is not installed:
```bash
sudo apt-get update
sudo apt-get install git
```

Clone this repository into your home directory:
```bash
cd ~
git clone https://github.com/zezevavai/ubuntu-server-initial-setup.git
```

Run the setup script
```bash
cd ubuntu-server-initial-setup
./setup.sh
```

# Setup prompts
When the setup script is run, you will be prompted to enter the username and password of the new user account. 

Following that, you will then be prompted to add a public ssh key (which should be from your local machine) for the new account. To generate an ssh key from your local machine:
```bash
ssh-keygen -t rsa
cat ~/.ssh/id_rsa.pub
```

Finally, you will be prompted to specify a [timezone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) for the server. It will be set to 'Asia/Jakarta' if you do not specify a value.

# Supported versions
This setup script has been tested against Ubuntu 18.04.