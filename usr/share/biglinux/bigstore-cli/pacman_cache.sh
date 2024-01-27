#!/usr/bin/env bash

#  Created: 2024/01/15
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

#  For me, programming has become more than just solving problems.
#  Now, it's about creating code that is so harmonious and well-structured
#  that it stands out for its own beauty.

# Load config file
. /usr/share/biglinux/bigstore-cli/config.sh

FileToSaveCacheFiltered="$cacheFolder/pacman_filtered.json"

FileToSaveUpdatesAvailable="$cacheFolder/pacman_updates.cache"


# Translate descriptions
DisableTranslate="false"


# Check if the first argument is empty
if [[ -z $1 ]]; then

    # If the system locale file exists for the language with the country code
    if [[ -e $localeFolder/${LANG%.*}.txt ]]; then
        localeFile="$localeFolder/${LANG%.*}.txt"

    # If the system locale file exists for the language without the country code
    elif [[ -e $localeFolder/${LANG:0:2}.txt ]]; then
        localeFile="$localeFolder/${LANG:0:2}.txt"

    else
        # If no locale file is found, display an error message and run without translated descriptions
        echo "Locale file not found: $localeFile
        Running without translation."
        DisableTranslate="true"
    fi

elif [[ "$1" == "disable-translate" ]]; then
    DisableTranslate="true"

elif [[ "$1" =~ "help" ]]; then
    echo "Usage: pacman_cache.sh [language code]
    Example: pacman_cache.sh pt_BR
    Example: pacman_cache.sh disable-translate
    Not use any argument to use the system locale.
    Files for translation must be in the folder: $localeFolder"
    exit 0

else
    if [[ -e $localeFolder/$1.txt ]]; then
        localeFile="$localeFolder/$1.txt"

    else
        echo "Locale file not found: $localeFile
        Running without translation."
        DisableTranslate="true"
    fi

fi

if [[ "$1" == "disable-translate" ]]; then
    DisableTranslate="true"
fi

# Create the folder to save files if it doesn't exist
if [[ ! -e $cacheFolder ]]; then
    mkdir -p $cacheFolder
fi
    LANG=C pacman -Qu > $FileToSaveUpdatesAvailable

# Function to transform the pacman output into a JSON array, using jq
pacmanJson() {
    LANG=C pacman -Ss | jq -Rsc '
    # Split the input by newline, filter out empty lines, and then reduce it
    reduce (split("\n") | .[] | select(. != "")) as $line ([]; 

    # Check if the line starts with spaces (typically descriptions in pacman output)
    if ($line | startswith("    "))
    then
      # If there are already items in the result array
      if (length > 0)
      then 
        # Add the description to the last package in the result array
        .[-1].description = ($line | ltrimstr("    "))
      else 
        .
      end
    else
      # Construct the package info object
      {
        "repo": ($line | split("/")[0]), # Extract the repository name
        "package": ($line | split("/")[1] | split(" ")[0]), # Extract the package name
        "installed": ($line | contains(" [installed") | tostring), # Check if the package is installed
        "version": (if $line | contains(" [installed: ") # Extract the installed version if available
                             then ($line | split(" [installed: ")[1] | split("]")[0])
                             else ($line | split(" ")[1] | split(" ")[0]) end)
      } as $package_info | 

      # Append the package info to the result array
      . + [$package_info]
    end
  )
' | sed 's|,{"repo":"|,\n{"repo":"|g;s|:null,|:"",|g;s|:"false",|:"",|g' # Split any package in one line and change null to "null"
}

# If the locale file exists, and not manual disabled the translation, use the translated description
if [[ "$DisableTranslate" == "false" ]]; then
    # Call the pacmanJson function to get pacman output in JSON format, and pipe it to awk
    # Specify the field separator to get individual fields from the JSON output
    # In -v localeFile="$localeFile", pass the locale file path to awk, the file with the translations
    pacmanJson | awk -v FS='"repo":"|","package":"|","version":"|","installed":"|","description":"|"},' -v localeFile="$localeFile" -v updatesFile="$FileToSaveUpdatesAvailable" '

    # BEGIN is run before the first line is read, and just execute one time
    BEGIN {

        # Read the updates file line by line
        while (getline < updatesFile) {
            split($0, a, " ");
            updates[a[1]] = a[4];
        }

        # Read the translations file line by line
        while (getline < localeFile) {

            # Split each line by tab and store the package name and translation in an array
            split($0, a, "\t");

            # Store the translation in the translations array, with the package name as the key
            translations[a[1]] = a[2];
        }

        # Initialize the output string with an opening bracket, to start the new JSON array
        out = "[\n";
    }

    # Now start the main loop, which is run for each line of the pacman output
    {
        # Store the fields in variables, to make the code more readable
        repo = $2;
        package = $3;
        description = $6;
        version = $5;
        installed = $4;

        # Escape double quotes and other escape sequences in the descriptions
        gsub(/(["\\])/,"\\\\&", description);
        gsub(/(["\\])/,"\\\\&", translations[package]);

        # Use translated description if available, otherwise use original description
        description_to_use = (translations[package] != "") ? translations[package] : description;

        # Verfify to not add duplicated packages and print json line
        update_info = (package in updates) ? updates[package] : "";

        # Verfify to not add duplicated packages and print json line
        if (!(package in processed_packages)) {
            processed_packages[package] = 1;
            out = out separator "{\"p\":\""package\
                                "\",\"d\":\""description_to_use\
                                "\",\"v\":\""version\
                                "\",\"i\":\""installed\
                                "\",\"u\":\""update_info\
                                "\",\"r\":\""repo\
                                "\",\"t\":\"p\"}";
            separator = ",\n";
        }

    }

    # END is run after the last line is read, and just execute one time
    END {
        # Add a closing bracket to the output string, to close the JSON array
        # We add an empty object at the end, because is faster than remove the last comma
        out = out ",\n{}]";

        # Finally print the output string
        print out;
    }' >"$FileToSaveCacheFiltered" # Redirect the output to the file

else
    # To generate JSON without translation, we don't really need awk
    # But we used because add only more or less 50ms in the total time
    # And awk is more easy to maintain this code because is the same
    # code used to generate JSON with translation, just without the translation part

    # Call the pacmanJson function to get pacman output in JSON format, and pipe it to awk
    # Specify the field separator to get individual fields from the JSON output
    pacmanJson | awk -v FS='"repo":"|","package":"|","version":"|","installed":"|","iver":"|","description":"|"},' -v updatesFile="$FileToSaveUpdatesAvailable" '

    # BEGIN is run before the first line is read, and just execute one time
    BEGIN {

        # Read the updates file line by line
        while (getline < updatesFile) {
            split($0, a, " ");
            updates[a[1]] = a[4];
        }

        # Initialize the output string with an opening bracket
        out = "[\n";
    }

    # Now start the main loop, which is run for each line of the pacman output
    {
        repo = $2;
        package = $3;
        description_to_use = $6;
        version = $5;
        installed = $4;

        # Escape double quotes and other escape sequences in the descriptions
        gsub(/(["\\])/,"\\\\&", description_to_use);

        # Verfify to not add duplicated packages and print json line
        update_info = (package in updates) ? updates[package] : "";

        # Verfify to not add duplicated packages and print json line
        if (!(package in processed_packages)) {
            processed_packages[package] = 1;
            out = out separator "{\"p\":\""package\
                                "\",\"d\":\""description_to_use\
                                "\",\"v\":\""version\
                                "\",\"i\":\""installed\
                                "\",\"u\":\""update_info\
                                "\",\"r\":\""repo\
                                "\",\"t\":\"p\"}";
            separator = ",\n";
        }
    }

    # END is run after the last line is read, and just execute one time
    END {
        out = out ",\n{}]";
        # Add a closing bracket to the output string, to close the JSON array
        # We add an empty object at the end, because is faster than remove the last comma

        # Finally print the output string
        print out;
    }' >"$FileToSaveCacheFiltered"
fi
