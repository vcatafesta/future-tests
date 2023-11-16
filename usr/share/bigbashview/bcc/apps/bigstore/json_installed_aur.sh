#!/bin/bash

aurInstalled=$(LANG=C pacman -Qm)

if [[ -n $aurInstalled ]]; then

    echo "$aurInstalled" | jq -c -R -s '
split("\n") |
map(select(length > 0)) |
map(split(" ") | {(.[0]): {"version": (.[1] | split("-")[0])}}) |
add
'

else

    echo '{}'

fi
