#!/bin/bash

LANG=C pacman -Qm | jq -R -s '
split("\n") |
map(select(length > 0)) |
map(split(" ") | {(.[0]): {"version": (.[1] | split("-")[0])}}) |
add
' 
