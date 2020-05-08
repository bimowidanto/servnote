#!/bin/bash

# Add the new user account
# Arguments:
#   Account Username
#   Account Password
#   Flag to determine if user account is added silently. (With / Without GECOS prompt)
function IndonesianRepos() {
#clear
sudo cp /etc/apt/sources.list /tmp/
sudo cp sources.list /etc/apt/sources.list
DIST_CODE=`cat /etc/lsb-release | grep -i code | cut -d "=" -f2`
sudo sed -i "s/focal/${DIST_CODE}/g" /etc/apt/sources.list
echo 'Please enter your preferred local Repos: '
options=("kambing.ui.ac.id" "repo.ugm.ac.id" "buaya.klas.or.id" "kartolo.sby.datautama.net.id" "mirror.poliwangi.ac.id" "As is-sesuai default" "Quit (use default system)")
select opt in "${options[@]}"
do
    case $opt in
        "kambing.ui.ac.id")
            echo "Kambing UI Repository"
	    #as-is
	    break
            ;;
        "repo.ugm.ac.id")
            echo "UGM Repository"
	    sudo sed -i 's/kambing.ui.ac.id/repo.ugm.ac.id/g' /etc/apt/sources.list
	    break
            ;;
        "buaya.klas.or.id")
            echo "Buaya KLAS Repository"
	    sudo sed -i 's/kambing.ui.ac.id/buaya.klas.or.id/g' /etc/apt/sources.list
	    break
            ;;
	"kartolo.sby.datautama.net.id")
            echo "Kartolo Datautama Repository"
	    sudo sed -i 's/kambing.ui.ac.id/kartolo.sby.datautama.net.id/g' /etc/apt/sources.list
	    break
	    ;;
        "mirror.poliwangi.ac.id")
            echo "Poliwangi Repository"
	    sudo sed -i 's/kambing.ui.ac.id/poliwangi.ac.id/g' /etc/apt/sources.list
	    break
            ;;
	"As is-sesuai default")
	    sudo cp /tmp/sources.list /etc/apt/sources.list	
	    break
	    ;;
        "Quit (use default system)")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
cat /etc/apt/sources.list
echo "Local repository updated"
}

function addUserAccount() {
    local username=${1}
    local password=${2}
    local silent_mode=${3}

    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --gecos '' "${username}"
    else
        sudo adduser --disabled-password "${username}"
    fi

    echo "${username}:${password}" | sudo chpasswd
    sudo usermod -aG sudo "${username}"
}

# Add the local machine public SSH Key for the new user account
# Arguments:
#   Account Username
#   Public SSH Key
function addSSHKey() {
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

# Execute a command as a certain user
# Arguments:
#   Account Username
#   Command to be executed
function execAsUser() {
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

# Modify the sshd_config file
# shellcheck disable=2116
function changeSSHConfig() {
    local sshKey=${1}
    if [ -z "$sshKey" ]
	then
      		echo "\SSH Key is empty, SSH password authentication will not be disable"
	else
      		sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    fi
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
}

# Setup the Uncomplicated Firewall
function setupUfw() {
    sudo ufw allow OpenSSH
    yes y | sudo ufw enable
}

# Create the swap file based on amount of physical memory on machine (Maximum size of swap is 4GB)
function createSwap() {
   local swapmem=$(($(getPhysicalMemory) * 2))

   # Anything over 4GB in swap is probably unnecessary as a RAM fallback
   if [ ${swapmem} -gt 4 ]; then
        swapmem=4
   fi

   sudo fallocate -l "${swapmem}G" /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
}

# Mount the swapfile
function mountSwap() {
    sudo cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
}

# Modify the swapfile settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function tweakSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    sudo sysctl vm.swappiness="${swappiness}"
    sudo sysctl vm.vfs_cache_pressure="${vfs_cache_pressure}"
}

# Save the modified swap settings
# Arguments:
#   new vm.swappiness value
#   new vm.vfs_cache_pressure value
function saveSwapSettings() {
    local swappiness=${1}
    local vfs_cache_pressure=${2}

    echo "vm.swappiness=${swappiness}" | sudo tee -a /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=${vfs_cache_pressure}" | sudo tee -a /etc/sysctl.conf
}

# Set the machine's timezone
# Arguments:
#   tz data timezone
function setTimezone() {
    local timezone=${1}
    echo "${1}" | sudo tee /etc/timezone
    sudo ln -fs "/usr/share/zoneinfo/${timezone}" /etc/localtime # https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
    sudo dpkg-reconfigure -f noninteractive tzdata
}

# Configure Network Time Protocol
function configureNTP() {
    sudo apt-get update
    sudo apt-get --assume-yes install ntp
}

# Gets the amount of physical memory in GB (rounded up) installed on the machine
function getPhysicalMemory() {
    local phymem
    phymem="$(free -g|awk '/^Mem:/{print $2}')"
    
    if [[ ${phymem} == '0' ]]; then
        echo 1
    else
        echo "${phymem}"
    fi
}

# Disables the sudo password prompt for a user account by editing /etc/sudoers
# Arguments:
#   Account username
function disableSudoPassword() {
    local username="${1}"

    sudo cp /etc/sudoers /etc/sudoers.bak
    sudo bash -c "echo '${1} ALL=(ALL) NOPASSWD: ALL' | (EDITOR='tee -a' visudo)"
}

# Reverts the original /etc/sudoers file before this script is ran
function revertSudoers() {
    sudo cp /etc/sudoers.bak /etc/sudoers
    sudo rm -rf /etc/sudoers.bak
}
