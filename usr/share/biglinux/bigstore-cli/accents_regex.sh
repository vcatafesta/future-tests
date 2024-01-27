#!/usr/bin/env bash

#  Created: 2024/01/18
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

# If we use grep, ripgrep, awk and another tools to search
# they don't find words with accents, for example:
# estável and estavel are different words to grep and another tools
# but to make it easier for the user, we will make the search insensitive to accents
# and change letters to regex.

# To use this script only call with the words you need to convert in regex
# Like, ./script.sh Bruno
# The output will be: br[uúùûüųū][nñń][oóòôõöøœ]

# This script converts a word to lowercase and replaces accented characters with their corresponding regular expressions.
# It uses a mapping of letters and their regex patterns to perform the replacements.
# The resulting word with regex is printed to the console.

# Turn all characters to lowercase
word=${*,,}

# Only certify that the variable is empty
regex_word=""

# Create a map with the letters and their regex
declare -A accents_mapping=(
    [a]='[aáàâãäåæ]'
    [á]='[aáàâãäåæ]'
    [à]='[aáàâãäåæ]'
    [â]='[aáàâãäåæ]'
    [ã]='[aáàâãäåæ]'
    [ä]='[aáàâãäåæ]'
    [å]='[aáàâãäåæ]'
    [æ]='[aáàâãäåæ]'
    [e]='[eéèêëęėē]'
    [é]='[eéèêëęėē]'
    [è]='[eéèêëęėē]'
    [ê]='[eéèêëęėē]'
    [ë]='[eéèêëęėē]'
    [ę]='[eéèêëęėē]'
    [ė]='[eéèêëęėē]'
    [ē]='[eéèêëęėē]'
    [i]='[iíìîïįī]'
    [í]='[iíìîïįī]'
    [ì]='[iíìîïįī]'
    [î]='[iíìîïįī]'
    [ï]='[iíìîïįī]'
    [į]='[iíìîïįī]'
    [ī]='[iíìîïįī]'
    [o]='[oóòôõöøœ]'
    [ó]='[oóòôõöøœ]'
    [ò]='[oóòôõöøœ]'
    [ô]='[oóòôõöøœ]'
    [õ]='[oóòôõöøœ]'
    [ö]='[oóòôõöøœ]'
    [ø]='[oóòôõöøœ]'
    [œ]='[oóòôõöøœ]'
    [u]='[uúùûüųū]'
    [ú]='[uúùûüųū]'
    [ù]='[uúùûüųū]'
    [û]='[uúùûüųū]'
    [ü]='[uúùûüųū]'
    [ų]='[uúùûüųū]'
    [ū]='[uúùûüųū]'
    [c]='[cçćč]'
    [ç]='[cçćč]'
    [ć]='[cçćč]'
    [č]='[cçćč]'
    [n]='[nñń]'
    [ñ]='[nñń]'
    [ń]='[nñń]'
    [s]='[sßśš]'
    [ß]='[sßśš]'
    [ś]='[sßśš]'
    [š]='[sßśš]'
    [y]='[yýÿ]'
    [ý]='[yýÿ]'
    [ÿ]='[yýÿ]'
    [z]='[zźżž]'
    [ź]='[zźżž]'
    [ż]='[zźżž]'
    [ž]='[zźżž]'
)

# For each letter in the word, check if it is in the map
for ((i = 0; i < ${#word}; i++)); do
    char=${word:i:1}

    # If the letter is in the map, add the regex to the variable
    if [[ ${accents_mapping[$char]} ]]; then
        # If the letter in the map, add the regex to the variable
        regex_word+="${accents_mapping[$char]}"

    else
        # If the letter is not in the map, add the letter to the variable
        regex_word+="$char"
    fi
done

# Print the words with regex
echo "$regex_word"