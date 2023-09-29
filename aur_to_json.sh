#!/bin/bash

zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq '[.[] | {Name, Description, Version}]' > aur_filtered.json

