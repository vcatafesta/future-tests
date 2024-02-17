#!/bin/bash

# Monitora o valor de download e o tamanho da pasta de cache do pacinstall

# Inicia variaveis de numero inteiro
declare -i folder_size_bytes download_bytes download_value download_multiplier

# Os valores são inteiro separado por ponto, dois numeros espaço e B, K, M ou G
# Mesmo se não precisar fazer download será 0.00 B
download="1.51 G"

# Captura o tamanho da pasta em bytes
du_value=$(du -s /var/cache/pacman/)

# Pega apenas o valor em bytes
folder_size_bytes=${du_value/[^0-9]*/}

# Remove a unidade e o ponto, deixando apenas o numeros
download_value=${download//[., BKMG]}

# Pega a última letra para a unidade
unit=${download: -1}

# Define o multiplicador para obter aprximadamente a quantidade de bytes, lembrando que remove o ponto então tem duas casas a mais
case $unit in
    B) download_multiplier=1 ;;
    K) download_multiplier=10 ;;
    M) download_multiplier=10240 ;;
    G) download_multiplier=10485760 ;;
    *) download_multiplier=0 ;;
esac

# Calcula o valor em bytes
download_bytes=$((download_value * download_multiplier))

# Calcula o quanto ainda falta para o download
declare -i remaining_bytes=$((download_bytes - folder_size_bytes))

# Calcula o percentual completado do download
declare -i percent_complete=$((download_bytes * 100 / folder_size_bytes))

# Retorna o valor em bytes para o valor original
number_to_show=$((remaining_bytes / download_multiplier))

# Adiciona o ponto novamente
number_to_show=${number_to_show%??}.${number_to_show: -2}

echo "Restam $number_to_show $unit para concluir o download."
echo "Percentual completado: $percent_complete%"
