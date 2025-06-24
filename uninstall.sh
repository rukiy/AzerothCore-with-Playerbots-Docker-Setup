#!/bin/bash

function ask_user() {
    read -p "$1 (y/n): " choice
    case "$choice" in
        y|Y ) return 0;;
        * ) return 1;;
    esac
}

if ask_user "This will uninstall azerothcore, continue?"; then

    cd azerothcore-wotlk
    docker compose down
    cd ..
    docker image prune -a
    if ask_user "Delete volumes? If you keep the volumes, a reinstall will only update."; then
        docker system prune -a
        docker volume rm azerothcore-wotlk_ac-client-data
        docker volume rm azerothcore-wotlk_ac-database
    fi

    if ask_user "Delete Server Data?, continue?"; then
        rm -rf wotlk/*
    fi
    
    if ask_user "Delete code source?, continue?"; then
        rm -rf azerothcore-wotlk
    fi
    exit 0
fi
