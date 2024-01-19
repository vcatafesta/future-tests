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
    if ($0 ~ /^[[:space:]]+/) {
        # Se a linha começa com espaço, é uma descrição
        description = substr($0, 5);
        gsub(/\\/, "\\\\", description);
        gsub(/"/, "\\\"", description);

        # Usar descrição traduzida se disponível
        translated_description = translations[package];
        if (translated_description != "") {
            gsub(/\\/, "\\\\", translated_description);
            gsub(/"/, "\\\"", translated_description);
            out = out "\"" "d" "\"" ":" "\"" translated_description "\"" "}";
        } else {
            out = out "\"" "d" "\"" ":" "\"" description "\"" "}";
        }

        separator = ",";
        next;
    }
    
    # Se a linha não começa com espaço, é uma nova entrada de pacote
    out = out separator "{";
    split($1, parts, "/");
    repo = parts[1];
    package = parts[2];
    version = $2;

    # Se o campo 3 tem um grupo, capturar isso
    group = "null";
    if ($3 ~ /\(.*\)/) {
        group = "\"" substr($3, 2, length($3) - 2) "\"";
    }
    
    # Verificar se o pacote está instalado
    installed = "false";
    if ($0 ~ /\[installed/) {
        installed = "true";
    }

    out = out "\"" "r" "\"" ":" "\"" repo "\"" ",";
    out = out "\"" "p" "\"" ":" "\"" package "\"" ",";
    out = out "\"" "v" "\"" ":" "\"" version "\"" ",";
    out = out "\"" "g" "\"" ":"  group ",";
    out = out "\"" "i" "\"" ":" "\"" installed "\"" ",";
}

END {
    out = out "]";
    print out;
}
' <(LANG=C pacman -Ss)
