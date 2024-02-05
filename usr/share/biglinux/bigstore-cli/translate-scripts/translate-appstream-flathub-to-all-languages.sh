#!/bin/bash

# Lot language codes
Language=("pt_BR" "es_ES" "ar_AA" "bn_BD" "id_ID" "hi_IN" "be_BY" "bg_BG" "zh_CN" "zh_TW" "hr_HR" "cs_CZ" "da_DK" "nl_NL" "et_EE" "fi_FI" "fr_FR" "de_DE" "el_GR" "he_IL" "hu_HU" "is_IS" "it_IT" "ja_JP" "ko_KR" "nb_NO" "pl_PL" "ro_RO" "ru_RU" "sk_SK" "sl_SI" "sv_FI" "sv_SE" "tr_TR" "uk_UA" )

# Loop for each language
for Lang in "${Language[@]}"; do

    # Verify if Lang is zh_CN or zh_TW, if not use ${Lang/_*/} to get only the first part of the language code
    if [[ "$Lang" == "zh_CN" ]] || [[ "$Lang" == "zh_TW" ]]; then
        LangCode=$Lang
    else
        LangCode=${Lang/_*/}
    fi

    if [ ! -f "/usr/share/biglinux/bigstore-cli/locale/flathub-$LangCode.json" ]; then
        # Create a new file, based on the language code from xml
        ./appstream-xml-flatpak-to-json-filtered-by-lang.sh $Lang /usr/share/swcatalog/xml/extra.xml.gz > /tmp/translating-flathub.json

        # Translate parts not translated
        ./flathub-translate.sh --lang $Lang /tmp/translating-flathub.json /usr/share/biglinux/bigstore-cli/locale/flathub-$LangCode.json
    fi
done
