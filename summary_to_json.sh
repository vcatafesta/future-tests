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
    if [[ -f "$app/pt_BR/desc" && -f "$app/pt_BR/summary" ]]; then
        # Use expansão de parâmetros para ler o conteúdo dos arquivos
        summary=$(echo "$(<"$app/pt_BR/summary")" | jq --raw-input --slurp '.')
        # Use jq para atualizar o arquivo JSON
        jq --arg app_name "$app_name" \
           --argjson summary "$summary" \
           '. + { ($app_name): {"summary": $summary} }' \
           tmp.json > tmp_new.json && mv tmp_new.json tmp.json
    fi
done

# Renomeie tmp.json para o nome do arquivo final
mv tmp.json summary_apps_pt_BR.json
