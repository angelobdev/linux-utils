#!/bin/bash

#COLORS
# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White
# Reset
Color_Off='\033[0m'       # Text Reset

#Sudo Check
if [ $EUID -ne "0" ]
then
    printf "${BRed}This script must be run in sudo mode.\n${Color_Off}"
    printf "${BRed}Try: sudo sh ${0}\n${Color_Off}"
    exit;
fi

#Updating packages
printf "${BPurple}Updating packages...${Color_Off}\n"
sudo apt update -y
printf "${BGreen}Done!\n${Color_Off}"

#Installing SED to edit files
sudo apt install sed -y

#Installing Apache2
printf "${BPurple}Installing Apache 2...\n"
sudo apt install apache2 -y
printf "${BGreen}Done!\n${Color_Off}"

#Installing MySQL server
printf "${BPurple}Installing MySQL server...${Color_Off}\n"
sudo apt install mysql-server -y

printf "${BYellow}Configuring wordpress access...\n${Color_Off}"
read -p "Enter MySQL password:" -s mysql_psw
echo
read -p "Confirm password:" -s mysql_psw_conf
echo

while [[ "$mysql_psw" != "$mysql_psw_conf" ]]
do
	printf "${BRred}Passwords are not the same!\n${Color_Off}"
    	read -p "Enter MySQL password:" -s mysql_psw
    	echo
    	read -p "Confirm password:" -s mysql_psw_conf
    	echo
done

#TODO CHECK
mysql -uroot << MYSQL_END
DROP USER wordpress@localhost;
CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '${mysql_psw}';
GRANT ALL PRIVILEGES ON *.* TO 'wordpress'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_END

#Installing PHP@7.4
printf "${BPurple}Installing PHP@7.4 ...${Color_Off}\n"

sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y

sudo apt install php7.4 libapache2-mod-php7.4 php7.4-curl php7.4-intl php7.4-zip php7.4-soap php7.4-xml php7.4-gd php7.4-mbstring php7.4-bcmath php7.4-common php7.4-xml php7.4-mysqli -y

sudo a2enmod php7.4
sudo a2enmod rewrite
sudo service apache2 restart

chown -R www-data:www-data /var/www/html

printf "${BGreen}Done!\n${Color_Off}"

#Increase RAM limit
sed -i "s/memory_limit.*/memory_limit = 1024M/" /etc/php/7.4/apache2/php.ini
sudo service apache2 restart

#Configuring VirtualHost
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/default.conf.copy

printf "<VirtualHost *:80>\n\tServerAdmin webmaster@localhost\n\tDocumentRoot /var/www/html\n\t<Directory /var/www/html>\n\t\tOptions Indexes FollowSymLinks MultiViews\n\t\tAllowOverride all\n\t\tRequire all granted\n\t</Directory>\n\tErrorLog \${APACHE_LOG_DIR}/error.log\n\tCustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

sudo service apache2 restart

#Installing Wordpress
printf "${BPurple}Installing Wordpress...\n${Color_Off}"

mysql -uroot -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"

cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

touch /tmp/wordpress/.htaccess
mkdir /tmp/wordpress/wp-content/upgrade

rm /var/www/html/index.html
sudo cp -a /tmp/wordpress/. /var/www/html

sudo chmod 755 /var/www/html/
sudo find /var/www/html/ -type d -exec chmod 750 {}
sudo find /var/www/html/ -type f -exec chmod 640 {} 

sudo rm /var/www/html/wp-config.php

#wp-config.php
printf  "<?php\ndefine( 'DB_NAME', 'wordpress' );\ndefine( 'DB_USER', 'wordpress' );\ndefine( 'DB_PASSWORD', '${mysql_psw}' );\ndefine( 'DB_HOST', 'localhost' );\ndefine( 'DB_CHARSET', 'utf8' );\ndefine( 'DB_COLLATE', '' );\n\n" >> /var/www/html/wp-config.php

curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php

prefix=$(head -100 /dev/urandom | tr -dc a-zA-Z0-9 | fold -w 6 | head -1) #Random prefix to be safer

printf  "\n\$table_prefix = '${prefix}_';\n\ndefine( 'WP_DEBUG', false );\nif ( ! defined( 'ABSPATH' ) ) {\n\tdefine( 'ABSPATH', __DIR__ . '/' );\n}\nrequire_once ABSPATH . 'wp-settings.php';\n?>" >> /var/www/html/wp-config.php

printf "${BGreen}Done!\n${Color_Off}" 

#\Asking phpMyAdmin
read -p "Do you want to install phpMyAdmin? (Y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo
    sudo apt update
	sudo apt install phpmyadmin -y
	ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
	printf "\n\nLocation: http://localhost/phpmyadmin \n"
	printf "${BGreen}Done!\n${Color_Off}"
fi

printf "${BPurple}Congrats! You have successfully installed Wordpress!\n${Color_Off}"

exit
#END
