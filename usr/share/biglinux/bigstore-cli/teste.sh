#!/usr/bin/env bash

/usr/share/biglinux/pactrans/bin/pactrans --yolo --install nemo nautilus 2>&1 | while read line; do
    echo "$line" | grep -oP '(\d+)%' | while read -r percent; do
        # Extrai apenas os números do percentual
        num=$(echo "$percent" | grep -oP '\d+')
        # Verifica se está na fase de download ou instalação
        if echo "$line" | grep -q 'Downloading'; then
            stage="downloading"
        elif echo "$line" | grep -q 'reinstalling\|installing'; then
            stage="installing"
        else
            stage="unknown"
        fi
        # Gera a saída JSON
        echo "{\"stage\":\"$stage\",\"progress\":$num}"
    done
done