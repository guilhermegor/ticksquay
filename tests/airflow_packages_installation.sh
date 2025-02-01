#!/bin/bash

echo "Testing packages..."

# active containers whose name starts with 'mktdata_scheduler-'
containers=$(docker ps -q --filter "name=mktdata_scheduler-")

echo -e "Containers matching 'mktdata_scheduler-*':\n$containers"

# iterate over available containers
for container in $containers; do
    #   container's name without the leading '/'
    container_name=$(docker inspect --format '{{.Name}}' $container | sed 's/\///')
    echo "- $container_name:"
    #   check if the container is running
    if docker ps -q -f id=$container; then
        #   if the container is running check wheter the package is installed
        echo "  * stpstone = \"0.1.2\": "
        echo "$(docker exec $container python -c "import stpstone; print(stpstone.__version__)")"
    else
        echo "Erro: Contêiner '$container_name' não encontrado ou não está em execução."
    fi
done
