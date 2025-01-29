#!/bin/bash

echo "Testing packages..."

# Obtenha a lista de contêineres cujo nome começa com 'mktdata_scheduler-'
containers=$(docker ps -q --filter "name=mktdata_scheduler-")

# Exibir os contêineres encontrados com quebra de linha
echo -e "Containers matching 'mktdata_scheduler-*':\n$containers"

# Iterar sobre todos os contêineres
for container in $containers; do
    container_name=$(docker inspect --format '{{.Name}}' $container | sed 's/\///')  # Nome do contêiner sem barra no início
    echo "- $container_name:"
    
    # Verifique se o contêiner está em execução
    if docker ps -q -f id=$container; then
        # Se o contêiner estiver rodando, execute o comando para verificar a versão do stpstone
        echo "  * stpstone = \"0.1.0\": "
        echo "$(docker exec $container python -c "import stpstone; print(stpstone.__version__)")"
    else
        echo "Erro: Contêiner '$container_name' não encontrado ou não está em execução."
    fi
done
