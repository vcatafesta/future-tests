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

# Defining the paths of the scripts
aurSearchScript="/usr/share/biglinux/bigstore-cli/aur_search.sh"
pacmanSearchScript="/usr/share/biglinux/bigstore-cli/pacman_search.sh"
flatpakSearchScript="/usr/share/biglinux/bigstore-cli/flatpak_search.sh"

# Checking if the -j parameter was provided
jsonMode=false
if [ "$1" = "-j" ]; then
    jsonMode=true
    shift # Remove the -j parameter from the arguments
fi

# No argument or --help
if [ $# -eq 0 ] || [ "$1" == "--help" ]; then
    echo "Usage: $0 [options] [search term]"
    echo "Without arguments, it will search all."
    echo ""
    echo "Options:"
    echo "    --help      Show this help message"
    echo "    --aur       Search only in AUR"
    echo "    --flatpak   Search only in Flatpak"
    echo "    --pacman    Search only in Pacman"
    echo "    --all       Search in both AUR and Pacman"
    echo "    -j          Output in JSON format"
    exit 0
fi

# Determining search mode
searchMode="all"
if [ "$1" == "--aur" ]; then
    searchMode="aur"
    shift # Remove the --aur parameter
elif [ "$1" == "--pacman" ]; then
    searchMode="pacman"
    shift # Remove the --pacman parameter
elif [ "$1" == "--flatpak" ]; then
    searchMode="flatpak"
    shift # Remove the --flatpak parameter
elif [ "$1" == "--all" ]; then
    searchMode="all"
    shift # Remove the --all parameter
fi

# Executing the search based on the mode
execute_search() {
    if [ "$searchMode" = "aur" ]; then
        $aurSearchScript "$@"
    elif [ "$searchMode" = "pacman" ]; then
        $pacmanSearchScript "$@"
    elif [ "$searchMode" = "flatpak" ]; then
        $flatpakSearchScript "$@"
    else
        $aurSearchScript "$@"
        $pacmanSearchScript "$@"
        $flatpakSearchScript "$@"
    fi
}

# Processing the output based on the mode
if $jsonMode; then
    # JSON Mode
    echo '['
    execute_search -j "$@" | LANG=C sort | LANG=C cut -d' ' -f2-
    echo '{}]'

else
    # Normal Terminal Mode
    execute_search "$@" | LANG=C sort -r | LANG=C cut -d' ' -f2- | LANG=C sed 's|\t,,,|\n    |g'
fi
