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
source /usr/share/biglinux/bigstore-cli/config.sh

# Folder to save list of packages
FileToSaveCacheFiltered="$cacheFolderHome/flatpak_filtered.json"
TmpAllFlatpak="$cacheFolderHome/flatpak_all_pkgs.cache"
TmpInstalledFlatpak="$cacheFolderHome/flatpak_Installed_pkgs.cache"
TmpUpdateFlatpak="$cacheFolderHome/flatpak_Update_pkgs.cache"

# Similiar to apt update or pacman -Sy
# flatpak remote-ls --updates

{ # All packages
    flatpak remote-ls --app --columns=name,description,application,version,branch,origin | sort -u >$TmpAllFlatpak
    if [[ $? != 0 ]]; then
        flatpak remote-ls --cached --app --columns=name,description,application,version,branch,origin | sort -u >$TmpAllFlatpak
        if [[ $? != 0 ]]; then
            exit 1
        fi
    fi
} &

{ # Update available
    flatpak remote-ls --updates --columns=name,description,application,version,branch,origin | sort -u >$TmpUpdateFlatpak
    if [[ $? != 0 ]]; then
        flatpak remote-ls --cached --updates --columns=name,description,application,version,branch,origin | sort -u >$TmpUpdateFlatpak
        if [[ $? != 0 ]]; then
            exit 1
        fi
    fi
} &

# # Installed packages
flatpak list --columns=name,description,application,version,branch,origin | sort -u >$TmpInstalledFlatpak &

# Translate descriptions
DisableTranslate="false"

# Check if the first argument is empty
if [[ -z $1 ]]; then
    # If the system locale file exists for the language with the country code
    if [[ -e $localeFolder/flatpak_${LANG%.*}.txt ]]; then
        localeFile="$localeFolder/flatpak_${LANG%.*}.txt"

    # If the system locale file exists for the language without the country code
    elif [[ -e $localeFolder/flatpak_${LANG:0:2}.txt ]]; then
        localeFile="$localeFolder/flatpak_${LANG:0:2}.txt"

    else
        # If no locale file is found, display an error message and run without translated descriptions
        echo "Locale file not found: $localeFile
        Running without translation."
        DisableTranslate="true"
    fi

elif [[ "$1" == "disable-translate" ]]; then
    DisableTranslate="true"

elif [[ "$1" =~ "help" ]]; then
    echo "Usage: aur_cache_with_translation.sh [language code]
    Example: aur_cache_with_translation.sh pt_BR
    Example: aur_cache_with_translation.sh disable-translate
    Not use any argument to use the system locale.
    Files for translation must be in the folder: $localeFolder"
    exit 0

else
    if [[ -e $localeFolder/flatpak_$1.txt ]]; then
        localeFile="$localeFolder/flatpak_$1.txt"

    else
        echo "Locale file not found: $localeFile
        Running without translation."
        DisableTranslate="true"
    fi
fi

if [[ "$1" == "disable-translate" ]]; then
    DisableTranslate="true"
fi

wait

if [[ "$DisableTranslate" == "false" ]]; then

    awk -v installedPackages="$TmpInstalledFlatpak" -v updatePackages="$TmpUpdateFlatpak" -v localeFile="$localeFile" '
    BEGIN {
        FS = "\t"; # Define o separador de campos como tab

        # Ler pacotes instalados
        while (getline < installedPackages) {
            split($0, a, FS);
            installed[a[3]] = 1; # Usa o ID do pacote como chave
        }
        close(installedPackages);

        # Ler pacotes com atualizações disponíveis
        while (getline < updatePackages) {
            split($0, a, FS);
            updateKey = a[3] FS a[5] FS a[6]; # Cria uma chave única usando id, branch e origin
            updates[updateKey] = 1; # Marca a atualização disponível para essa chave
        }
        close(updatePackages);

        # Read the translations file line by line
        while (getline < localeFile) {

            # Split each line by tab and store the package name and translation in an array
            split($0, a, "\t");

            # Store the translation in the translations array, with the package name as the key
            translations[a[1]] = a[2];
        }

        print "["; # Início do JSON array
        first = 1; # Para controlar a vírgula antes dos objetos JSON
    }

    # Processa a lista completa de pacotes
    {
        # name = $1;
        # description = $2;
        # id = $3;
        # version = $4;
        # branch = $5;
        # origin = $6;
        if (FNR > 1 && !first) print ","; # Adiciona vírgula antes de cada objeto JSON, exceto o primeiro
        first = 0; # Reseta a flag após o primeiro objeto

        # Use translated description if available, otherwise use original description
        description_to_use = (translations[$3] != "") ? translations[$3] : $2;

        updateKey = $3 FS $5 FS $6; # Cria uma chave única para o pacote atual usando id, branch e origin

        # Cria o objeto JSON para o pacote atual
        printf "{\"p\":\"%s\",\"d\":\"%s\",\"id\":\"%s\",\"v\":\"%s\",\"branch\":\"%s\",\"origin\":\"%s\",\"i\":%s,\"up\":%s}",
            $1, description_to_use, $3, $4, $5, $6,
            (installed[$3] ? "\"true\"" : "\"false\""),
            (updates[updateKey] ? "\"true\"" : "\"false\"");
    }

    END {
        print "]"; # Fecha o JSON array
    }' "$TmpAllFlatpak" | sort -u >$FileToSaveCacheFiltered

else

    awk -v installedPackages="$TmpInstalledFlatpak" -v updatePackages="$TmpUpdateFlatpak" -v localeFile="$localeFile" '
    BEGIN {
        FS = "\t"; # Define o separador de campos como tab

        # Ler pacotes instalados
        while (getline < installedPackages) {
            split($0, a, FS);
            installed[a[3]] = 1; # Usa o ID do pacote como chave
        }
        close(installedPackages);

        # Ler pacotes com atualizações disponíveis
        while (getline < updatePackages) {
            split($0, a, FS);
            updateKey = a[3] FS a[5] FS a[6]; # Cria uma chave única usando id, branch e origin
            updates[updateKey] = 1; # Marca a atualização disponível para essa chave
        }
        close(updatePackages);

        print "["; # Início do JSON array
        first = 1; # Para controlar a vírgula antes dos objetos JSON
    }

    # Processa a lista completa de pacotes
    {
        if (FNR > 1 && !first) print ","; # Adiciona vírgula antes de cada objeto JSON, exceto o primeiro
        first = 0; # Reseta a flag após o primeiro objeto

        updateKey = $3 FS $5 FS $6; # Cria uma chave única para o pacote atual usando id, branch e origin

        # Cria o objeto JSON para o pacote atual
        printf "{\"p\":\"%s\",\"d\":\"%s\",\"id\":\"%s\",\"v\":\"%s\",\"branch\":\"%s\",\"origin\":\"%s\",\"i\":%s,\"updateAvailable\":%s}",
            $1, $2, $3, $4, $5, $6,
            (installed[$3] ? "\"true\"" : "\"false\""),
            (updates[updateKey] ? "\"true\"" : "\"false\"");
    }

    END {
        print "]"; # Fecha o JSON array
    }' "$TmpAllFlatpak" | sort -u >$FileToSaveCacheFiltered

fi
