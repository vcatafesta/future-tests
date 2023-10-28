#!/bin/bash


if [[ ! -e "$HOME/.config/bigstore" ]]; then
    mkdir -p "$HOME/.config/bigstore"
fi

if [[ "$configOption" = "save" ]]; then
    echo $configContent > "$HOME/.config/bigstore/config.json"
elif [[ "$configOption" = "load" ]]; then
    if [[ -e "$HOME/.config/bigstore/config.json" ]]; then
        cat "$HOME/.config/bigstore/config.json"
    else
        echo "{}"
    fi
elif [[ "$configOption" = "delete" ]]; then
    rm "$HOME/.config/bigstore/config.json"
else
    echo "Invalid config option"
fi