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
. /usr/share/biglinux/bigstore-cli/config.sh

# Load JSON file for search
json_file="$cacheFolder/aur_filtered.json"

# Function to check the file size (>2MB)
fileSize=$(stat -c %s "$json_file")

# Verify if exist '/var/tmp/pamac/aur_filtered.json' and if have less than 2MB
# If have less of 2MB or not exist, try generate new cache file
if [[ ! -e $json_file || $fileSize -le 2097152 ]]; then
    echo "Cache file '$json_file' is less than 2MB, which might indicate an error."
    echo "Trying generate new cache file."
    aur_cache.sh
    echo "Try again."
    exit 1
fi

# Verify if the option -j was passed
json_output=false
if [ "$1" == "-j" ]; then
    json_output=true
    shift  # Remove the option -j from arguments
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
search_cmd="rg -N $uncompress_flag -i --pcre2 '$first_term_regex' '$json_file'"

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

    # eval run the crazy ripgrep command, and awk read the results
    # The awk part of code is just to classify the results in json
    # FS is the field separator, any characters beetween | is a field separator
    eval $search_cmd | awk -v FS='"p":"|","d":"|","v":"|","i":"|","iver":"|","up":"|","vote":"|","pop":"|","ood":"|","maint":"|"' -v terms="$(accents_regex.sh $*)" '

    # $0 is the entire line                         - Complete line
    # $1 is the first field, before "p":"           - Package
    # $2 is the second field, before ","d":"        - Description
    # $3 is the third field, before ","v":"         - Version
    # $4 is the fourth field, before ","i":"        - Installed ( true or false )
    # $5 is the fifth field, before ","iver":"      - Installed version
    # $6 is the sixth field, before ","up":"        - Update available ( true or false )
    # $7 is the seventh field, before ","vote":"    - Votes
    # $8 is the eighth field, before ","pop":"      - Popularity
    # $9 is the ninth field, before ","ood":"       - Out of date in unix timestamp
    # $10 is the tenth field, before ","maint":"    - Maintainer
    # $11 is the eleventh field, after last "       - End of line

    # BEGIN run one time before the first line is read
    BEGIN { 

        # Split the terms in array t, with space as separator
        # Any word in search is a term
        split(terms, t, " "); 
    }

    # Now start the main loop, which is run for each line of the pacman output
    {
        # Count is 50, because the max count is 50
        # For each term, if the package name match with term, count -= 1
        # If the package is installed, count -= 10
        # If the package have update, count -= 10
        # This make easy to sort the results
        count = 50;

        # For each term, if the package name match with term, count -= 1
        for (i in t) {
            if ($2 ~ t[i]) count -= 1;
        }

        # If the package is installed, count -= 10
        if ($7 == "true") {
            count -= 10;
        }

        # If the package have update, count -= 10
        if ($5 == "true") {
            count -= 10;
        }

        # Print the count and all information from json line
        print count, $0;
    }'
    # }' | LANG=C sort | LANG=C cut -d' ' -f2- # Sort the results by count, to show the best results first and remove the count

else
    # eval run the crazy ripgrep command, and awk read the results
    # The awk part of code is just to classify the results in json
    # FS is the field separator, any characters beetween | is a field separator
    eval $search_cmd | awk -v FS='"p":"|","d":"|","v":"|","i":"|","iver":"|","up":"|","vote":"|","pop":"|","ood":"|","maint":"|"' -v terms="$(accents_regex.sh $*)" '

    # BEGIN run one time before the first line is read
    BEGIN {
        # Use strange characters as separator, to avoid problems
        OFS=" "

        # Split the terms in array t, with space as separator
        # Any word in search is a term
        split(terms, t, " ");

        # Define colors, for text output more beautiful
        blue="\x1b[34m"
        yellow="\x1b[33m"
        gray="\x1b[36m"
        green="\x1b[32m"
        red="\x1b[31m"
        resetColor="\x1b[0m"
    }

    # Now start the main loop, which is run for each line of the pacman output
    {

        package = $2;
        description = $3;
        version = $4;
        installed = $5; # true or false
        iver = $6; # installed version
        up = $7; # update available
        vote = $8; # votes
        pop = $9; # popularity
        ood = $10; # out of date in unix timestamp
        maint = $11; # maintainer

        count = 50;
        for (i in t) {
            if (package ~ t[i]) count -= 1;
        }
        if (installed == "true") {
            count -= 10;
            if (up == "true") {
                installed="installed ";
                update=" new version "gray version " ";
                version=iver;
                count -= 10;
            } else {
                update = "";
                installed="installed  ";}
        } else {
            update = "";
            installed="";
        }
        if (ood != "null") {
            ood = "  Out of date since " strftime("%F",ood);
        } else {
            ood = "";
        }
        if (maint == "null") {
            maint = "\x1b[31m Orphan";
        }

        # Removendo a contagem do print final
        print count, blue "AUR" gray "/" yellow package "  " green installed gray version " " yellow update resetColor " (" gray "Votes " resetColor vote gray " Pop " resetColor pop gray " Maintainer " resetColor maint ")" red ood resetColor "\t,,," description "\t,,,";
    }'
    # }' | sort -rn | cut -d'' -f2- | LANG=C sed 's|\t,,,|\n    |g'
fi