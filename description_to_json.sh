#!/bin/bash

# O diretório de base para todas as descrições
BASE_DIR="/usr/share/bigbashview/bcc/apps/big-store/description/"

# Inicialize um arquivo JSON vazio
echo '{}' > tmp.json

# Para cada pasta em BASE_DIR
for app in $BASE_DIR*/; do
    # Use expansão de parâmetros para obter o nome da aplicação
    appname_tmp=${app%/}
    app_name="${appname_tmp##*/}"
    
    # Verifique se os arquivos desc e summary existem
    if [[ -f "${app}pt_BR/desc" && -f "${app}pt_BR/summary" ]]; then
        # Use expansão de parâmetros para ler o conteúdo dos arquivos
        desc_content=$(<"${app}pt_BR/desc")
        summary_content=$(<"${app}pt_BR/summary")
        
        # Use jq para atualizar o arquivo JSON
        jq --arg app_name "$app_name" \
           --arg desc_content "$desc_content" \
           --arg summary_content "$summary_content" \
           '.[$app_name] = {"desc": $desc_content, "summary": $summary_content}' \
           tmp.json >> description_apps_pt_BR.json
    fi
done
 
