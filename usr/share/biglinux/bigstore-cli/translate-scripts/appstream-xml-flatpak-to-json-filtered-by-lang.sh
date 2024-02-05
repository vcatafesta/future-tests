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

# Show help explain $1 is lang code and $2 is path to xml file or xml.gz
if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "" ] || [ "$2" == "" ]; then
  echo "This script help to filter not translated appstream summary and description"
  echo ""
  echo "Usage: LANG_CODE [XML_FILE]"
  echo "Example: pt_BR /usr/share/swcatalog/xml/extra.xml"
  echo ""
  echo "LANG_CODE is the language code to filter"
  echo "XML_FILE is the path to the XML file to filter"
  echo ""
  echo "Automatically search for another 2 variations of LANG_CODE like pt_BR, pt-BR, pt"
  echo ""
  echo "If have summary or description in LANG_CODE, say in json, description_found true or summary_found true"
  echo "If not have, use original language and say false to description_found or summary_found"
  exit 0
fi

# Verify if xq is installed
if ! command -v xq &> /dev/null; then
  echo "xq is not installed, generally is in yq package"
  exit 1
fi

# Check if $1 is a valid lang code, 2 chars, lowercase, 2 chars
if [[ ! "$1" =~ ^[a-z]{2}_[A-Z]{2}$ ]]; then
  echo "Invalid lang code: $1"
  exit 1
fi

LANG_CODE=$1

# Verify if $2 is a .gz and use zcat to decompress and pass to xq
# Change tags <p> to %%p%%, </p> to %%/p%%, <ul> to %%ul%%, </ul> to %%/ul%%, <li> to %%li%%, </li> to %%/li%%
# Because xq transform tags in json array or object
function xml_to_stdout() {
  if [[ "$1" =~ \.gz$ ]]; then
    zcat "$1" | sed 's|<p>|%%p%%|g;s|<ul>|%%ul%%|g;s|<li>|%%li%%|g;s|</p>|%%/p%%|g;s|</ul>|%%/ul%%|g;s|</li>|%%/li%%|g;'
  else
    sed 's|<p>|%%p%%|g;s|<ul>|%%ul%%|g;s|<li>|%%li%%|g;s|</p>|%%/p%%|g;s|</ul>|%%/ul%%|g;s|</li>|%%/li%%|g;' "$1"
  fi
}

xml_to_stdout $2 | xq -c --arg lang "$LANG_CODE" --arg lang_alt "${LANG_CODE/_/-}" --arg lang_simple "${LANG_CODE/_*}" '.[].component[] | 
{
  "@type": .["@type"],
  id: .id,
  name: (
    if .name | type == "string" then
      .name
    elif .name | type == "array" then
      (.name[] | select(type == "object" and .["@xml:lang"] == $lang) | .["#text"]) // 
      (.name[] | select(type == "object" and .["@xml:lang"] == $lang_alt) | .["#text"]) // 
      (.name[] | select(type == "object" and .["@xml:lang"] == $lang_simple) | .["#text"]) // 
      (.name[] | select(type == "string"))
    else
      .name | tostring
    end
  ),
  description: (
    if .description | type == "string" then
      .description
    elif .description | type == "array" then
      (.description[] | select(type == "object" and .["@xml:lang"] == $lang) | tostring) // 
      (.description[] | select(type == "object" and .["@xml:lang"] == $lang_alt) | tostring) // 
      (.description[] | select(type == "object" and .["@xml:lang"] == $lang_simple) | tostring) // 
      (.description[] | select(type == "string"))
    else
      .description.p | tostring
    end
  ),
  description_found: (
    if .description | type == "array" then
      any(.description[]; type == "object" and (.["@xml:lang"] == $lang or .["@xml:lang"] == $lang_alt or .["@xml:lang"] == $lang_simple))
    else
      false
    end
  )
}'  | sed 's|{\\"@xml:lang\\":\\"[^\]*\\",\\"#text\\":\\"||g
s|%%/p%%\\"}",|%%/p%%",|g
s|%%/p%%| </p> |g
s|%%p%%| <p> |g
s|%%li%%| <li> |g
s|%%/li%%| </li> |g
s|%%/ul%%| </ul> |g
s|%%ul%%| <ul> |g
s|\\\\\\"|\\"|g
s|\\"}","description_found|","description_found|g' |
sed -E 's|[\]?\\n +| |g' | sort -u

# Transform back tags changed in xml_to_stdout function