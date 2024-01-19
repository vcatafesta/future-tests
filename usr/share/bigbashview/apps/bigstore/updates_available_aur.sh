#!/bin/bash

# Obter lista de pacotes instalados do AUR
installed_packages=$(pacman -Qm | awk '{print $1}')

# Construir o comando grep com múltiplos -e para cada pacote
grep_pattern=""
for pkg in $installed_packages; do
    grep_pattern+=" -e \"$pkg\""
done

# Executar o script json_dump_aur_with_translation.sh e filtrar os pacotes instalados
bash json_dump_aur_with_translation.sh | grep $grep_pattern #> filtered_packages.txt

# Comparar as versões dos pacotes instalados com as versões filtradas
# while IFS=' ' read -r installed_pkg installed_ver; do
#     # Procura o pacote no arquivo de pacotes filtrados
#     repo_info=$(grep "\"p\":\"$installed_pkg\"" filtered_packages.txt)
# 
#     if [ ! -z "$repo_info" ]; then
#         # Extrai a versão do pacote do repositório
#         repo_ver=$(echo $repo_info | cut -d ',' -f3 | cut -d '"' -f4)
# 
#         if [ "$installed_ver" != "$repo_ver" ]; then
#             echo "Pacote: $installed_pkg - Instalado: $installed_ver, Disponível: $repo_ver"
#         fi
#     fi
# done < <(pacman -Qm)
