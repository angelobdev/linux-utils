#!/bin/bash

Color_Off='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red

#Config files checker
printf "${Red}Apache config:\n${Color_Off}"
cat /etc/apache2/sites-available/000-default.conf
echo

printf "${Red}PHP memory config:\n${Color_Off}"
cat /etc/php/7.4/apache2/php.ini | grep memory_limit
echo

printf "${Red}WP config:\n${Color_Off}"
cat /var/www/html/wp-config.php
echo

exit
#END
