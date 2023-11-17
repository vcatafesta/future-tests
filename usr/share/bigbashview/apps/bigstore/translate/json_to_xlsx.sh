#!/bin/bash

rm -R ~/.cache/bigstoreTranslation 2> /dev/null
mkdir ~/.cache/bigstoreTranslation

../json_search_pacman.sh > ~/.cache/bigstoreTranslation/pacman.json
../json_search_aur.sh    > ~/.cache/bigstoreTranslation/aur.json

python json_to_xlsx.py ~/.cache/bigstoreTranslation/pacman.json ~/.cache/bigstoreTranslation/aur.json ~/.cache/bigstoreTranslation/pacmanAndAur.xlsx

echo 'Arquivo criado: ~/.cache/bigstoreTranslation/pacmanAndAur.xlsx'