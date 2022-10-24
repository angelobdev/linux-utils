#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset

# Regular Colors
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Purple='\033[0;35m'       # Purple

#Removing packages

if [[ $EUID != "0" ]]
then
	printf "${Red}This script must be run in sudo mode.\n${Color_Off}"
	printf "${Yellow}Try: ${Color_Off}sudo sh ${0}\n"
	exit
fi

printf "${Purple}Removing Wordpress install and dependencies\n${Color_Off}"

sudo apt purge apache2 -y
sudo apt purge mysql-server -y
sudo apt purge php7.4 libapache2-mod-php7.4 php7.4-curl php7.4-intl php7.4-zip php7.4-soap php7.4-xml php7.4-gd php7.4-mbstring php7.4-bcmath php7.4-common php7.4-xml php7.4-mysqli -y

sudo rm -rf -v /tmp/wordpress
sudo rm -rf -v /var/www/html*

sudo apt autoremove -y
sudo apt autoclean -y

sudo apt update -y
sudo apt upgrade -y

printf "${Green}Done!\n${Color_Off}"
exit
