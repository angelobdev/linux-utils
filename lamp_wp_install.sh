#!/bin/bash

#COLORS
# Bold
Black='\033[1;30m'       # Black
Red='\033[1;31m'         # Red
Green='\033[1;32m'       # Green
Yellow='\033[1;33m'      # Yellow
Blue='\033[1;34m'        # Blue
Purple='\033[1;35m'      # Purple
Cyan='\033[1;36m'        # Cyan
White='\033[1;37m'       # White
# Reset
Color_Off='\033[0m'       # Text Reset

#Custom print
cprint() {
	printf "${1}${2}\n${Color_Off}"
}

#Sudo Check
if [ $EUID -ne "0" ]
then
	cprint $Red "This script must be run in sudo mode."
	cprint $Yellow "Try: sudo sh ${0}"
	exit;
fi

#Config
cprint $Cyan "Before we start you need to configure some variables:"

read -p "First insert MySQL username: " mysql_usr

read -p "Now MySQL password:" -s mysql_psw
echo
read -p "Confirm password:" -s mysql_psw_conf
echo

while [[ "$mysql_psw" != "$mysql_psw_conf" ]]
do
        cprint $Red "Passwords are not the same! Retry."
        read -p "Enter MySQL password:" -s mysql_psw
        echo
        read -p "Confirm password:" -s mysql_psw_conf
        echo
done

cprint $Cyan "Installation will start soon..."

#Updating packages
cprint $Purple "Updating Packages..."
sudo apt update -y
cprint $Green "Done updating packages!"

#Installing SED if not installed yet
sudo apt install sed -y

#Installing Apache2
cprint $Purple "Installing Apache2..."
sudo apt install apache2 -y 
cprint $Green "Done installing Apache2!"

#Installing MySQL server
cprint $Purple "Installing MySQL server..."
sudo apt install mysql-server -y

mysql -uroot << MYSQL_END
	DROP USER IF EXISTS '${mysql_usr}'@'localhost';
	CREATE USER '${mysql_usr}'@'localhost' IDENTIFIED BY '${mysql_psw}';
	GRANT ALL PRIVILEGES ON *.* TO '${mysql_usr}'@'localhost' WITH GRANT OPTION;
	FLUSH PRIVILEGES;
MYSQL_END

cprint $Green "Done installing MySQL server!"

#Installing PHP@7.4
cprint $Purple "Installing PHP@7.4 ..."

sudo apt install software-properties-common -y

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

sudo apt-get install php7.4 libapache2-mod-php7.4 php7.4-curl php7.4-intl php7.4-zip php7.4-soap php7.4-xml php7.4-gd php7.4-mbstring php7.4-bcmath php7.4-common php7.4-xml php7.4-mysqli -y

sudo a2enmod php7.4
sudo a2enmod rewrite
sudo service apache2 restart

chown -R www-data:www-data /var/www/html

cprint $Green "Done installing PHP@7.4!"

#Increase RAM limit
sed -i "s/memory_limit.*/memory_limit = 1024M/" /etc/php/7.4/apache2/php.ini
sudo service apache2 restart

#Configuring VirtualHost
mv /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.copy

printf "<VirtualHost *:80>\n\tServerAdmin webmaster@localhost\n\tDocumentRoot /var/www/html\n\t<Directory /var/www/html>\n\t\tOptions Indexes FollowSymLinks MultiViews\n\t\tAllowOverride all\n\t\tRequire all granted\n\t</Directory>\n\tErrorLog \${APACHE_LOG_DIR}/error.log\n\tCustomLog \${APACHE_LOG_DIR}/access.log combined\n</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

sudo service apache2 restart

#Installing Wordpress
cprint $Purple "Installing Wordpress..."

mysql -uroot -e "CREATE DATABASE IF NOT EXISTS wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;" #Database setup

cd /tmp
curl -O https://wordpress.org/latest.tar.gz #Getting latest wordpress
tar xzf latest.tar.gz

touch /tmp/wordpress/.htaccess
mkdir /tmp/wordpress/wp-content/upgrade

rm /var/www/html/index.html
sudo cp -a /tmp/wordpress/. /var/www/html #Copying it in html dir

sudo chmod 755 /var/www/html/
sudo find /var/www/html/ -type d -exec chmod 750 {} #Configuring permissions
sudo find /var/www/html/ -type f -exec chmod 640 {} 

#Configuring wp-config.php
printf  "<?php\ndefine( 'DB_NAME', 'wordpress' );\ndefine( 'DB_USER', '${mysql_usr}' );\ndefine( 'DB_PASSWORD', '${mysql_psw}' );\ndefine( 'DB_HOST', 'localhost' );\ndefine( 'DB_CHARSET', 'utf8' );\ndefine( 'DB_COLLATE', '' );\n\n" >> /var/www/html/wp-config.php

curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php

prefix=$(head -100 /dev/urandom | tr -dc a-zA-Z0-9 | fold -w 6 | head -1) #Random prefix to be safer

printf  "\n\$table_prefix = '${prefix}_';\n\ndefine( 'WP_DEBUG', false );\nif ( ! defined( 'ABSPATH' ) ) {\n\tdefine( 'ABSPATH', __DIR__ . '/' );\n}\nrequire_once ABSPATH . 'wp-settings.php';\n?>" >> /var/www/html/wp-config.php

cprint $Green "Done installing Wordpress!" 

#\Asking phpMyAdmin
read -p "Do you want to install phpMyAdmin? (Y/n) " -n 1 -r pmaok
if [[ $pmaok =~ ^[Yy]$ ]]
then
    	echo;
    	sudo apt update -y
	sudo apt install phpmyadmin -y
	ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
	cprint $Green "Done installing phpMyAdmin"
fi

cprint $Cyan "Congrats! You have successfully installed Wordpress!"
echo

#SUMMARY
cprint $Yellow "********************** BRIEF SUMMARY ****************************"
cprint $Yellow "PHP VERSION: 7.4"
echo
cprint $Yellow "MySQL user: ${mysql_usr}"
cprint $Yellow "MySQL password: <THE ONE YOU CHOSE>"
echo
cprint $Yellow "You can now finish the setup at http://localhost/ (from this machine)"
cprint $Yellow "Or http://<Your IP Address>/ (from local network)"
echo

if [[ $pmaok =~ ^[Yy]$ ]]
then
	cprint $Yellow "You can visit phpMyAdmin at http://localhost/phpmyadmin (from this machine)"
	cprint $Yellow "Or http://<Your IP Address>/phpmyadmin (from local network)"	
fi

cprint $Yellow "*****************************************************************"

exit
#END
