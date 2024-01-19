#!/usr/bin/env bash

#  Created: 2024/01/16
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

# Define the URL and file paths
url="https://aur.manjaro.org/packages-meta-ext-v1.json.gz"
destFile="packages-meta-ext-v1.json"
tempDestFile="temp_$destFile"
destGzFile="$destFile.gz"
tempDestGzFile="temp_$destFile.gz"

# Function to check the file size (>5MB)
checkFileSize() {
    fileSize=$(stat -c %s "$cacheFolder/$tempDestGzFile")
    if [ $fileSize -ge 5242880 ]; then
        return 0
    else
        echo "Downloaded file is less than 5MB, which might indicate an error."
        return 1
    fi
}

# Function for downloading with aria2c
downloadAria2c() {
    if type aria2c >/dev/null 2>&1; then
        aria2c -d "$cacheFolder" -o "$tempDestGzFile" -x 6 -s 6 "$url" && return 0 || return 1
    else
        return 1
    fi
}

# Function for downloading with curl
downloadCurl() {
    if type curl >/dev/null 2>&1; then
        curl -L -o "$cacheFolder/$tempDestGzFile" "$url" && return 0 || return 1
    else
        return 1
    fi
}

# Function for downloading with wget
downloadWget() {
    if type wget >/dev/null 2>&1; then
        wget -O "$cacheFolder/$tempDestGzFile" "$url" && return 0 || return 1
    else
        return 1
    fi
}

# Function for decompressing the file
decompressFile() {
    if type pigz >/dev/null 2>&1; then
        pigz -dkf "$cacheFolder/$tempDestGzFile" && mv "$cacheFolder/$tempDestFile" "$cacheFolder/$destFile" && return 0 || return 1
    else
        gunzip -c "$cacheFolder/$tempDestGzFile" >"$cacheFolder/$tempDestFile" && mv "$cacheFolder/$tempDestFile" "$cacheFolder/$destFile" && return 0 || return 1
    fi
}

# Remove old temporary files if it exists
rm -f "$cacheFolder/$tempDestGzFile"
rm -f "$cacheFolder/$tempDestFile"

# Try downloading with aria2c, then curl, then wget
if ! downloadAria2c && ! downloadCurl && ! downloadWget; then
    echo "Download failed with all methods. Exiting."
    exit 1
fi

# Check if the downloaded file size is adequate
if ! checkFileSize; then
    echo "Downloaded file did not pass the size check. Exiting."
    exit 1
fi

# Try decompressing the file
if ! decompressFile; then
    echo "Decompression failed. Exiting."
    exit 1
fi

# Remove old temporary files if it exists
mv -f "$cacheFolder/$tempDestGzFile" "$cacheFolder/$destGzFile"
rm -f "$cacheFolder/$tempDestFile"

echo "File downloaded and decompressed successfully."