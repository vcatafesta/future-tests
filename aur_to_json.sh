#!/bin/bash

#zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq '[.[] | {Name, Description, Version}]' > aur_filtered.json
zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq 'reduce .[] as $item ({}; .[$item.Name] = {description: $item.Description, version: $item.Version})' > aur_filtered.json
