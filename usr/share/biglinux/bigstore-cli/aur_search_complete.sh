#!/usr/bin/env bash

#  Created: 2024/01/17
#
#  Copyright (c) 2023-2024, Bruno Gonçalves <www.biglinux.com.br>
#  All rights reserved.
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

# Load config file
. /usr/share/biglinux/bigstore-cli/config.sh

# Arquivo JSON para busca
json_file="$cacheFolder/packages-meta-ext-v1.json"

if [[ ! -e $json_file ]]; then
    json_file="$cacheFolder/packages-meta-v1.json.gz"
    uncompress_flag='-z'  
fi

# Função para criar uma regex para cada termo
create_regex_for_term() {
    echo "(\"Name\":\"[^\"]*$1[^\"]*\"|\"Description\":\"[^\"]*$1[^\"]*\")"
}

# Executa a busca para o primeiro termo
first_term_regex=$(create_regex_for_term "$1")
search_cmd="rg -N $uncompress_flag -i --no-unicode --pcre2 '$first_term_regex' '$json_file'"

# Adiciona cada termo adicional ao comando de busca
for term in "${@:2}"; do
    term_regex=$(create_regex_for_term "$term")
    search_cmd+=" | rg -i -N --no-unicode --pcre2 '$term_regex'"
done

# Executa o comando de busca e processa os resultados
eval $search_cmd | awk -v terms="$*" '
BEGIN { FS = "\"Name\":\"|\",\"Description\":\""; split(terms, t, " ") }
{
    count = 0;
    for (i in t) {
        if ($2 ~ t[i]) count++;
    }
    print count, $0;
}' | LANG=C sort -r | LANG=C cut -d' ' -f2-
