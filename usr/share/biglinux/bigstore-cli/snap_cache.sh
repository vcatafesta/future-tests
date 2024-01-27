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
FileToSaveCacheFiltered="$cacheFolderHome/snap_filtered.json"
AllSnapCache="$cacheFolderHome/snap_all_pkgs.cache"
InstalledSnap="$cacheFolderHome/snap_Installed_pkgs.cache"

# # Installed packages
LANG=C snap list | awk 'NR>1 { print $1 "\t" $2}' | sort -u >$InstalledSnap &

# Translate descriptions
DisableTranslate="false"

# Check if the first argument is empty
if [[ -z $1 ]]; then
    # If the system locale file exists for the language with the country code
    if [[ -e $localeFolder/snap_${LANG%.*}.txt ]]; then
        localeFile="$localeFolder/snap_${LANG%.*}.txt"

    # If the system locale file exists for the language without the country code
    elif [[ -e $localeFolder/snap_${LANG:0:2}.txt ]]; then
        localeFile="$localeFolder/snap_${LANG:0:2}.txt"

    else
        # If no locale file is found, display an error message and run without translated descriptions
        echo "Locale file not found: $localeFile
        Running without translation."
        DisableTranslate="true"
    fi

elif [[ "$1" == "disable-translate" ]]; then
    DisableTranslate="true"

elif [[ "$1" =~ "help" ]]; then
    echo "Usage: snap_cache.sh [language code]
    Example: snap_cache.sh pt_BR
    Example: snap_cache.sh disable-translate
    Not use any argument to use the system locale.
    Files for translation must be in the folder: $localeFolder"
    exit 0

else
    if [[ -e $localeFolder/snap_$1.txt ]]; then
        localeFile="$localeFolder/snap_$1.txt"

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

    awk -v installedPackages="$InstalledSnap" -v localeFile="$localeFile" '
    BEGIN {
        FS = "\t"; # Use separator as tab

        # Read installed packages
        while (getline < installedPackages) {
            split($0, a, FS);
            installed[a[1]] = 1; # Use package ID as key
        }
        close(installedPackages);

        # Read the translations file line by line
        while (getline < localeFile) {

            # Split each line by tab and store the package name and translation in an array
            split($0, a, "\t");

            # Store the translation in the translations array, with the package name as the key
            translations[a[1]] = a[2];
        }

        # print "["; # Start of JSON array
        first = 1; # To control the comma before JSON objects
    }

    # Process the complete list of packages
    {
        # name = $1;
        # description = $2;
        # id = $3;
        # pkgid = $4;
        # version = $5;
        # installed = $6;
        if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
        first = 0; # Reset flag after the first object

        # Use translated description if available, otherwise use original description
        description_to_use = (translations[$3] != "") ? translations[$3] : $2;

        # Escape invalid JSON characters
        gsub(/(["\\])/,"\\\\&", description_to_use);

        # Create the JSON object for the current package
        printf "{\"n\":\"%s\",\"d\":\"%s\",\"p\":\"%s\",\"v\":\"%s\",\"ic\":\"%s\",\"i\":%s,\"t\":\"s\"}",
            $1, description_to_use, $3, $5, $6,
            (installed[$1] ? "\"true\"" : "\"\"");
    }

    END {
        print ","; # Close the JSON array
    }' "$AllSnapCache" | sort -u >$FileToSaveCacheFiltered

else

    awk -v installedPackages="$InstalledSnap" '
    BEGIN {
        FS = "\t"; # Use separator as tab

        # Read installed packages
        while (getline < installedPackages) {
            split($0, a, FS);
            installed[a[1]] = 1; # Use package ID as key
        }
        close(installedPackages);

        # print "["; # Start of JSON array
        first = 1; # To control the comma before JSON objects
    }

    # Process the complete list of packages
    {
        if (FNR > 1 && !first) print ","; # Add comma before each JSON object, except the first
        first = 0; # Reset flag after the first object

        # Escape invalid JSON characters
        gsub(/(["\\])/,"\\\\&", $2);

        # Create the JSON object for the current package
        printf "{\"n\":\"%s\",\"d\":\"%s\",\"p\":\"%s\",\"v\":\"%s\",\"ic\":\"%s\",\"i\":%s,\"t\":\"s\"}",
            $1, $2, $3, $5, $6,
            (installed[$3] ? "\"true\"" : "\"\""),
    }

    END {
        print ","; # Close the JSON array
    }' "$AllSnapCache" | sort -u >$FileToSaveCacheFiltered

fi
