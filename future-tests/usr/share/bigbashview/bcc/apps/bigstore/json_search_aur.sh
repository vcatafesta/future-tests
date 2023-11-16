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
    zcat /var/tmp/pamac/packages-meta-ext-v1.json.gz | jq -c '[.[] | {p: .Name, d: .Description, v: .Version}]' > $FileToSaveCacheFiltered

fi

cat "$FileToSaveCacheFiltered"
