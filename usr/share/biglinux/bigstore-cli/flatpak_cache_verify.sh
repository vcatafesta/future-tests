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

# Json with all packages
FileToSaveCacheFiltered="$cacheFolderHome/flatpak_filtered.json"

# Get the modification date of the JSON file
json_mod_time=$(stat -c %Y "$FileToSaveCacheFiltered")

# Get the last history of flatpak commands
flatpak_info=$(LANG=C flatpak history --columns=time -vv 2>&1)

# Get the date of the last flatpak command
flatpak_last_time=$(date -d "$(echo "$flatpak_info" | tail -n1)" +%s)

# Check if the JSON file is older than the last flatpak command
if [ "$json_mod_time" -lt "$flatpak_last_time" ]; then
    echo "The JSON file is older than the last flatpak command. Running flatpak_cache.sh..."
    flatpak_cache.sh
    exit 0
else
    # List active flatpak installations and check appstream folders
    echo "$flatpak_info" | rg 'F: Opening' | rg -o '/.*' | while read -r line; do
        appstream_folder="${line}/appstream"

        # Check if the appstream folder exists
        if [ -d "$appstream_folder" ]; then
            # Get the modification date of the appstream folder
            appstream_mod_time=$(stat -c %Y "$appstream_folder")

            # Compare modification dates
            if [ "$appstream_mod_time" -gt "$json_mod_time" ]; then
                echo "The appstream folder in $line was modified after the JSON file. Running flatpak_cache.sh..."
                flatpak_cache.sh
                exit 0
            fi
        fi
    done
fi
