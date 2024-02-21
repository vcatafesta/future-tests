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

{ # All packages, use two sort commands to repeated app select the latest version
    flatpak remote-ls --app --columns=name,description,application,version,branch,origin | sort -r | sort -uk1,3 -t $'\t' >$TmpAllFlatpak
    if [[ $? != 0 ]]; then
        flatpak remote-ls --cached --app --columns=name,description,application,version,branch,origin | sort -r | sort -uk1,3 -t $'\t' >$TmpAllFlatpak
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
    echo "Usage: aur_cache.sh [language code]
    Example: aur_cache.sh pt_BR
    Example: aur_cache.sh disable-translate
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

# If the locale file exists, and not manual disabled the translation, use the translated description
if [[ "$DisableTranslate" == "false" ]]; then

    awk_translate="-v localeFile=$localeFile"
    awk_file="$awk_folder/flatpak_cache_with_translate.awk"
else

    awk_translate=''
    awk_file="$awk_folder/flatpak_cache_without_translate.awk"
fi

# Filter all with awk
awk -v installedPackages="$TmpInstalledFlatpak" -v updatePackages="$TmpUpdateFlatpak" $awk_translate -f $awk_file "$TmpAllFlatpak" | sort -u >$FileToSaveCacheFiltered