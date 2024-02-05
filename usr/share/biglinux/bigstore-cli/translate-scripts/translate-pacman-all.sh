#!/bin/bash

# Lot language codes
Language=("pt_BR" "es_ES" "ar_AA" "bn_BD" "id_ID" "hi_IN" "be_BY" "bg_BG" "zh_CN" "zh_TW" "hr_HR" "cs_CZ" "da_DK" "nl_NL" "et_EE" "fi_FI" "fr_FR" "de_DE" "el_GR" "he_IL" "hu_HU" "is_IS" "it_IT" "ja_JP" "ko_KR" "nb_NO" "pl_PL" "ro_RO" "ru_RU" "sk_SK" "sl_SI" "sv_FI" "sv_SE" "tr_TR" "uk_UA" )

# Loop for each language
for Lang in "${Language[@]}"; do
    ./translate-pacman.sh --lang "$Lang"
done
