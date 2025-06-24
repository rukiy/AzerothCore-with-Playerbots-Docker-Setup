#!/bin/bash

client_init() {
    source_file="client.tar.gz"
    target_path="wotlk"
    echo "$source_file unzip to $target_path"
    rm -rf "$target_path"
    mkdir -p $target_path
    tar -zxvf $source_file -C $target_path
    echo "chmod $target_path"
    chmod -R 755 $source_file
}

client_init