#!/bin/bash

Reset='\033[0m'       # Text Reset
Start='\033[0;33m'       # Yellow
Doing='\033[0;35m'       # Purple
Done='\033[0;32m'        # Green

# A simple auto-update script
function autoupdate(){
        printf "${Start}Auto Updating Started...\n"
        printf "${Reset}"
        START_TIME=$SECONDS

        printf "${Doing}Removing unused packages...\n"
        printf "${Reset}"
        sudo apt autoremove

        printf "${Doing}Cleaning...\n"
        printf "${Reset}"
        sudo apt autoclean

        printf "${Doing}Updating packages...\n"
        printf "${Reset}"
        sudo apt update

        printf "${Doing}Upgrading packages...\n"
        printf "${Reset}"
        sudo apt upgrade

        ELAPSED=$(($SECONDS - $START_TIME))
        printf "${Done}Done in ${ELAPSED} seconds!\n"
        printf "${Reset}"
}
