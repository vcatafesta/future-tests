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

# Load JSON file for search
json_file="$cacheFolder/pacman_filtered.json"

# Function to check the file size (>2MB)
fileSize=$(stat -c %s "$json_file")

# Verify if exist '/var/tmp/pamac/aur_filtered.json' and if have less than 1MB
# If have less of 2MB or not exist, try generate new cache file
if [[ ! -e $json_file || $fileSize -le 1048576 ]]; then
    echo "Cache file '$json_file' is less than 1MB, which might indicate an error."
    echo "Trying generate new cache file."
    pacman_cache.sh
    echo "Try again."
    exit 1
fi

# Verify if the option -j was passed
json_output=false
if [ "$1" == "-j" ]; then
    json_output=true
    shift # Remove the option -j from arguments
fi

# Function to create a regex for each term
# The regex is used to search in the JSON file
# With lot \ because need scape the ", and reading json file with lot of "
# Remember p is the package name and d is the description
create_regex_for_term() {
    echo "(\"p\":\"[^\"]*$1[^\"]*\"|\"d\":\"[^\"]*$1[^\"]*\")"
}

# Use the first word in search as the first term
# The accents_regex.sh is used to change accentuation of letters
# Using regex, to replace for example a with [aáàâãäåæ]
# The result is used in before function to use in ripgrep to search
first_term_regex=$(create_regex_for_term "$(accents_regex.sh $1)")
search_cmd="rg -N -i --pcre2 '$first_term_regex' '$json_file'"

# If have more than one word in search, add each word to search
# Filtering the results with ripgrep from the previous search
# Search for example, BigLinux Store is that crazy line:
# rg -N -i --pcre2 '("p":"[^"]*B[iíìîïįī]gL[iíìîïįī][nñń][uúùûüųū]x[^"]*"|"d":"[^"]*B[iíìîïįī]gL[iíìîïįī][nñń][uúùûüųū]x[^"]*")' '/var/tmp/pamac/aur_filtered.json' | rg -i -N --pcre2 '("p":"[^"]*St[oóòôõöøœ]r[eéèêëęėē][^"]*"|"d":"[^"]*St[oóòôõöøœ]r[eéèêëęėē][^"]*")'
for term in "${@:2}"; do
    term_regex=$(create_regex_for_term "$(accents_regex.sh $term)")
    search_cmd+=" | rg -i -N --pcre2 '$term_regex'"
done

# This script can output in json format or in text format
if $json_output; then

    awk_file='awk/pacman_search_json.awk'
else

    awk_file='awk/pacman_search.awk'
fi

# eval run the crazy ripgrep command, and awk read the results
# The awk part of code is just to classify the results in json
# FS is the field separator, any characters beetween | is a field separator
eval $search_cmd | awk -v FS='"p":"|","d":"|","v":"|","i":"|","u":"|","r":"|","g":"|","t":"|"},' -f $awk_file -v terms="$(accents_regex.sh $*)"
