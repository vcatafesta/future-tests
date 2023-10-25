#!/bin/bash

for i in *.xlsx; do

    echo "Exporting ${i/.xlsx/.json}"
    python xlsx_to_json.py "$i" | jq -c > "${i/.xlsx/.json}"

done
