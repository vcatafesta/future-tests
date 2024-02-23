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

# Example of usage, first declare variable, after call function:
# PacmanPkgName="gimp" getPacmanInfoByPkgName
# By default use this functions only generate variables and arrays
# Nothing is printed on screen
# See in the end of file an example of usage like this:
# TestPacmanInfoByPkgName=true PkgName=firefox ./read_pacman.sh


# Declare an associative array to hold package search results
declare -A DllName

# Declare a simple array to hold package names
declare -a AppNames

# Run the pacman search command and store its output
CommandOutput=$(grep -e '^w_metadata ' -e 'installed_file' /usr/bin/winetricks)
# Initialize an empty variable for the package name
appName=""

# Loop through each line of the command output
while IFS= read -r line; do
    # Check if the line starts with an alphabet (usually means it's a package name)
    if [[ "${line:0:1}" = [a-zA-Z] ]]; then
        # Extract the package name from the line
        appName="${line#* }"
        appName="${appName%% *}"
        # Add the package name to the AppNames array
        AppNames+=("$appName")
    else
        # Store the Dll of the package
        key="${appName}:Dll"
        dll="${line##*/}"
        DllName["$key"]+=" ${dll%%[ \"]*}"
    fi
done <<< "$CommandOutput"

# Loop through each package name to show its information
for pkgName in "${AppNames[@]}"; do

    if [[ "${DllName["$pkgName:Dll"]}" =~ \.dll ]]; then
        echo "$pkgName ${DllName["$pkgName:Dll"]}"
    fi
done
