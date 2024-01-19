#!/bin/bash

# Arquivo JSON para busca
json_file="/var/tmp/pamac/packages-meta-ext-v1.json"

if [[ ! -e $json_file ]]; then
    json_file="/var/tmp/pamac/packages-meta-v1.json.gz"
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
