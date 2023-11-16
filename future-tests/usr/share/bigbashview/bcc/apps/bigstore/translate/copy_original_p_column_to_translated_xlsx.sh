#!/bin/bash

for i in *.xlsx; do

    echo "Correcting p column in $i"
    python copy_original_p_column_to_translated_xlsx.py "$HOME/.cache/bigstoreTranslation/pacmanAndAur.xlsx" "$i"

done
