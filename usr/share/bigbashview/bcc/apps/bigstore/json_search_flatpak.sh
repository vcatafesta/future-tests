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
FileToSaveCacheFiltered="$HOME/.cache/bigstore/flatpak_filtered.cache"


if [[ ! -e $FileToSaveCacheFiltered ]]; then

    if [[ ! -e $FolderToSaveFiles ]]; then
        mkdir -p $FolderToSaveFiles
    fi

    # Flatpak
    LANGUAGE=C appstreamcli search . | jq -R -s -c '
    split("---\n")
    | map(select(. != ""))
    | map(split("\n") 
        | map(select(test(": ")))
        | map(split(": "))
        | reduce .[] as $item ({}; .[$item[0]] = $item[1])
    )
    | map(select(has("Bundle")))
    | map({p: .Name, n: .Bundle, d: .Summary, g: .Icon})' | sed -E 's|flatpak:[^/]*/([^/]*)[^"]*|\1|g' > $FileToSaveCacheFiltered
fi

cat "$FileToSaveCacheFiltered"
