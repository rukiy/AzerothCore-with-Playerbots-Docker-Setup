#!/bin/bash

clear_containers() {
    containers=("ac-worldserver" "ac-authserver" "ac-database" "ac-db-import" "ac-client-data-init")
    echo "rm containers: ${containers[*]}"
    docker rm "${containers[@]}"
}

clear_containers