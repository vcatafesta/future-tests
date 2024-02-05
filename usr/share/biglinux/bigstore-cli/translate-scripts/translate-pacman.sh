#!/usr/bin/env bash

#  Created: 2024/01/16
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

# Function to display help
function displayHelp {
    echo "Usage: $0 --lang [LANGUAGE_CODE]"
    echo "This script checks for missing translations of Pacman packages for the specified language."
    echo "Example: $0 --lang pt_BR"
}

# Verify if the first argument is empty
if [ "$1" == "--lang" ] && [ -n "$2" ]; then
    localeCode="${2/-/_}"
    transLangCode="${2/_/-}" # Trans command uses - instead of _ for language codes
else
    displayHelp
    exit 1
fi

# Define variables
outputFile="/tmp/translatedContent.txt"
translationFile="/usr/share/biglinux/bigstore-cli/locale/pacman_$localeCode.txt"
allpacmanToTranslate="/tmp/pacmanAllPkgsToTranslate.cache"

# Need add the locale to the system, without this have problem with accents
sudo localectl set-locale "$localeCode.UTF-8"
export LANG="$localeCode.UTF-8" LANGUAGE="$localeCode.UTF-8"

# Get all pacman application id with descriptions
pacman -Ss | sed -E 's|[^ /]*/([^ ]*).*|\1|g' | sd '\n  +' '\t' | sort -uk1,1 >$allpacmanToTranslate

# Load translated IDs and descriptions into an associative array
declare -A translatedIds
while IFS=$'\t' read -r id description; do
    translatedIds["$id"]="$description"
done <$translationFile

# Clean old file
>"$outputFile"

# Instantiate arrays to store batch descriptions and IDs
declare -a batchDescriptions
declare -a batchIds
batchSize=0
totalTranslated=0
totalToTranslate=$(grep -c '[^\t]' $allpacmanToTranslate)

# Function to translate a batch of descriptions
function translateBatch {
    joinedDescriptions=$(printf "%s\n" "${batchDescriptions[@]}")
    translatedText=$(trans --brief -t $transLangCode "$joinedDescriptions")
    IFS=$'\n' read -rd '' -a translatedLines <<<"$translatedText"

    for i in "${!translatedLines[@]}"; do
        # Verify if the ID was processed
        if [ -z "${translatedIds[${batchIds[i]}]}" ]; then
            echo -e "${batchIds[i]}\t${translatedLines[i]}" >>"$outputFile"
            translatedIds[${batchIds[i]}]=${translatedLines[i]} # Check as processed
        fi
    done

    echo "Translated $batchSize lines. Remaining: $((totalToTranslate - totalTranslated))"

    batchDescriptions=()
    batchIds=()
    batchSize=0
}

# Function to translate a single description
function translateSingle {
    translatedDescription=$(echo "$1" | trans --brief -t $transLangCode)
    # Verify if the ID was processed
    if [ -z "${translatedIds[$2]}" ]; then
        echo -e "$2\t$translatedDescription" >>"$outputFile"
        translatedIds[$2]=$translatedDescription # Check as processed
    fi
    echo "Translated 1 line. Total translated: $totalTranslated. Remaining: $((totalToTranslate - totalTranslated))"
}

# Loop through all descriptions
while IFS=$'\t' read -r id description; do
    if [[ -n $description && -z ${translatedIds[$id]} ]]; then
        remainingLines=$((totalToTranslate - totalTranslated))
        if [ $remainingLines -lt 20 ]; then
            # Translate single description if there are less than 20 lines remaining
            translateSingle "$description" "$id"
            ((totalTranslated++))
        else
            # Add description and ID to batch arrays
            batchDescriptions+=("$description")
            batchIds+=("$id")
            ((batchSize++))

            # Translate batch if it has 20 descriptions or if it is the last batch
            if [ $batchSize -eq 20 ] || [ $remainingLines -eq $batchSize ]; then
                totalTranslated=$((totalTranslated + batchSize))
                translateBatch
            fi
        fi
    elif [[ -n $description ]]; then
        # If the description is already translated, just add it to the output file
        echo -e "$id\t${translatedIds[$id]}" >>"$outputFile"
        ((totalTranslated++))
    fi
done <$allpacmanToTranslate

# Proccess the last batch if it is not empty
if [ $batchSize -gt 0 ]; then
    totalTranslated=$((totalTranslated + batchSize))
    translateBatch
fi

# Replace the old translation file with the new one
mv "$outputFile" "$translationFile"

echo "Translation completed. Check the file: $translationFile"
