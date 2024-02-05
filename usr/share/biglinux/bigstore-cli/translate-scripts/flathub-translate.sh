#!/bin/bash

#  Created: 2024/01/31
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
displayHelp() {
    echo "Usage: $0 --lang [LANGUAGE_CODE] [INPUT_FILE] [OUTPUT_FILE]"
    echo "This script translates 'summary' and 'description' fields in a JSON file if they are not already translated."
    echo "Example: $0 --lang pt_BR /tmp/translating.json /usr/share/biglinux/bigstore-cli/locale/appstream-extra-pt.json"
}

# Verify if the first argument is empty
if [ "$1" == "--lang" ] && [ -n "$2" ]; then
    localeCode="${2/-/_}"
    transLangCode="${2/_/-}" # trans command uses - instead of _ for language codes
else
    displayHelp
    exit 1
fi

# Add the locale to the system
sudo localectl set-locale "$localeCode.UTF-8"
export LANG="$localeCode.UTF-8" LANGUAGE="$localeCode.UTF-8"

# Path to the JSON file
jsonFile="$3"
newJsonFile="$4"

# New JSON file
echo "[]" > "$newJsonFile"

# Reading and updating each entry in the JSON
jq -c '.' "$jsonFile" | while read -r line; do
    description_found=$(echo "$line" | jq '.description_found')

    if [[ "$description_found" == "false" ]]; then
        description=$(echo "$line" | jq -r '.description')
        if [[ $description != "null" ]]; then
          echo "$description"
          translated_description=$(trans -no-auto --brief -t $transLangCode "$description")
        else
          translated_description="null"
        fi
        line=$(echo "$line" | jq --arg td "$translated_description" '.description = $td')
    fi

    # Add the translated line to the new JSON file
    jq -c --argjson obj "$line" '. += [$obj]' "$newJsonFile" > temp-flatpak.json && mv temp-flatpak.json "$newJsonFile"
done

echo "Translation completed."