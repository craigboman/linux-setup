#!/bin/bash

#==============================================================================
#
#         FILE: fedora-setup.sh
#        USAGE: sudo fedora-setup.sh
#
#  DESCRIPTION: Post-installation install script for Fedora 29/30/31/32 Workstation
#  INSPIRED BY: https://github.com/David-Else/fedora-ultimate-setup-script
#
# REQUIREMENTS: Fresh copy of Fedora 30/31/32/33 installed on your computer
#       AUTHOR: CRAIG BOMAN
#
#==============================================================================

#==============================================================================
# script settings and checks
#==============================================================================
set -euo pipefail
exec 2> >(tee "error_log_$(date -Iseconds).txt")

GREEN=$(tput setaf 2)
BOLD=$(tput bold)
RESET=$(tput sgr0)

if [ "$(id -u)" != 0 ]; then
    echo "You're not root! Run script with sudo" && exit 1
fi

if [[ $(rpm -E %fedora) -lt 29 ]]; then
    echo >&2 "You must install at least ${GREEN}Fedora 29${RESET} to use this script" && exit 1
fi

# >>>>>> start of user settings <<<<<<

#==============================================================================
# common packages to install/remove *arrays can be left empty, but don't delete
#==============================================================================
packages_to_remove=(
)

packages_to_install=(
    chromium
    chromium-libs-media-freeworld
    code
    composer
    conky
    docker
    docker-compose
    fail2ban
    feh
    ffmpeg
    filezilla
    geany
    gh
    git
    i3
    i3-status
    i3lock
    libva-intel-driver
    mpv
    mediainfo
    lshw
    java-1.8.0-openjdk
    jack-audio-connection-kit
    nodejs
    obs
    pgadmin
    redshift
    syncthing
    ShellCheck
    stow
    tldr
    tripwire
    ufw
    vlc
    wireshark
    xbacklight
    xclip
    zathura
    zathura-pdf-mupdf
    zathura-bash-completion
    zeal
    )

packages_to_download=(
    https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm
    https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=rpm
    https://www.expressvpn.works/clients/linux/expressvpn-3.9.0.75-1.x86_64.rpm
    https://dist.ipfs.io/go-ipfs/v0.9.0/go-ipfs_v0.9.0_linux-amd64.tar.gz
    https://go.skype.com/skypeforlinux-64.rpm
    https://zoom.us/client/latest/zoom_x86_64.rpm
)


#==============================================================================
# display user settings
#==============================================================================
cat <<EOL
${BOLD}Packages to install${RESET}
${BOLD}-------------------${RESET}
DNF packages: ${GREEN}${packages_to_install[*]}${RESET}
Node packages: ${GREEN}${node_global_packages_to_install[*]}${RESET}
${BOLD}Packages to remove${RESET}
${BOLD}------------------${RESET}
DNF packages: ${GREEN}${packages_to_remove[*]}${RESET}
EOL
read -rp "Press enter to install, or ctrl+c to quit"

#==============================================================================
# add default and conditional repositories
#==============================================================================
echo "${BOLD}Adding repositories...${RESET}"
dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# note the spaces to make sure something like 'notnode' could not trigger 'nodejs' using [*]
case " ${packages_to_install[*]} " in
*' code '*)
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    ;;&
*' gh '*)
    dnf -y config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    ;;
esac

#==============================================================================
# install packages
#==============================================================================
# echo "${BOLD}Removing unwanted programs...${RESET}"
# dnf -y remove "${packages_to_remove[@]}"

echo "${BOLD}Updating Fedora...${RESET}"
sudo dnf -y --refresh upgrade

echo "${BOLD}Installing packages...${RESET}"
sudo dnf -y install "${packages_to_install[@]}"

echo "${BOLD}Downloading tars...${RESET}"
cd ~/Downloads && wget "${packages_to_download[@]}"

echo "${BOLD}Installing IPFS ${RESET}"
cd ~/Downloads
tar -xvzf go-ipfs_v0.9.0_linux-amd64.tar.gz
cd go-ipfs
sudo bash install.sh
cd ~/Downloads
rm -rf go-ipfs-*

echo "${BOLD}Installing Zoom ${RESET}"
cd ~/Downloads
sudo dnf localinstall zoom_x86_64.rpm
rm zoom_x86_64.rpm

echo "${BOLD}Setting up ufw ${RESET}"
sudo ufw enable
sudo ufw deny 1:21/udp
sudo ufw deny 23:52/tcp
sudo ufw deny 23:52/udp
sudo ufw deny 54:79/tcp
sudo ufw deny 54:79/udp
sudo ufw deny 81:442/tcp
sudo ufw deny 81:442/udp
sudo ufw deny 444:65535/tcp
sudo ufw deny 444:65535/udp
Sudo ufw limit 22/tcp
Sudo ufw limit 22/udp
sudo ufw deny rpcbind
sudo systemctl enable ufw

echo "${BOLD}Setting up fail2ban ${RESET}"
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
EOF
sudo systemctl restart fail2ban
sudo fail2ban-client set sshd unbanip IP

echo "${BOLD}Setting up git ${RESET}"
clear
read -p "Enter git user.name" -n 1 username
git config --global user.name $username
read -p "Enter git user.email" -n 1 email
git config --global user.email $email

echo "${BOLD}Setting up pip ${RESET}"
pip install pipenv poetry cookiecutter youtube-dl tldr



=============================================================================
Congratulations, everything is installed!
Now use the setup script...
=============================================================================
EOL