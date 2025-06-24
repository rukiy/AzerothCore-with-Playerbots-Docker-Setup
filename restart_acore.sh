#!/bin/bash

restart_docker_containers() {
    containers=("ac-worldserver" "ac-authserver")

    echo "Restarting containers: ${containers[*]}"
    docker restart "${containers[@]}"
}

restart_docker_containers