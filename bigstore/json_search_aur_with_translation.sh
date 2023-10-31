#!/usr/bin/env bash

#  2023-2023, Bruno Gonçalves <www.biglinux.com.br>
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
#  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
#  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
#  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
#  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Folder to save list of packages
FolderToSaveFiles="$HOME/.cache/bigstore/"
FileToSaveCacheFiltered="$HOME/.cache/bigstore/aur_filtered.cache"


if [[ ! -e $FileToSaveCacheFiltered ]]; then

    if [[ ! -e $FolderToSaveFiles ]]; then
        mkdir -p $FolderToSaveFiles
    fi

    #zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq '[.[] | {Name, Description, Version}]' > aur_filtered.json
    # zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq 'reduce .[] as $item ({}; .[$item.Name] = {description: $item.Description, version: $item.Version})' > aur_filtered.json
zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq -r '.[] | .Name + "\t" + .Description + "\t" + .Version' | \
awk '
# Carregar traduções do arquivo translations.txt para um array associativo
BEGIN {
    while (getline < "translations.txt") {
        split($0, a, "\t");
        translations[a[1]] = a[2];
    }
    out = "[";
    separator = "";
}

{
    package = $1;
    description = $2;
    version = $3;

    # Escapar as aspas duplas e outras sequências de escape nas descrições
    gsub(/(["\\])/,"\\\\&", description);
    gsub(/(["\\])/,"\\\\&", translations[package]);
    gsub(/(["\\])/,"\\\\&", version);

    # Usar descrição traduzida se disponível
    translated_description = translations[package];
    if (translated_description != "") {
        out = out separator "{\"p\":\"" package "\",\"d\":\"" translated_description "\",\"v\":\"" version "\"}";
    } else {
        out = out separator "{\"p\":\"" package "\",\"d\":\"" description "\",\"v\":\"" version "\"}";
    }
    separator = ",";
}

END {
    out = out "]";
    print out;
}
' > "$FileToSaveCacheFiltered"

else

cat "$FileToSaveCacheFiltered"

fi
