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

# Folder to save list of packages
FolderToSaveFiles="$cacheFolderHome/snap_list_files/snap_list"
FolderToSaveFilesTmp="$cacheFolderHome/snap_list_files/snap_list_tmp"
AllSnapCache="$cacheFolderHome/snap_all_pkgs.cache"

if [ ! -e "$FolderToSaveFiles" ]; then
    mkdir -p "$FolderToSaveFiles"
fi

if [ ! -e "$FolderToSaveFilesTmp" ]; then
    mkdir -p "$FolderToSaveFilesTmp"

else
    rm -f "$FolderToSaveFilesTmp"/*
fi

# Annotation with all possible options to use in the API
#https://api.snapcraft.io/api/v1/snaps/search?confinement=strict,classic&fields=anon_download_url,architecture,channel,download_sha3_384,summary,description,binary_filesize,download_url,last_updated,package_name,prices,publisher,ratings_average,revision,snap_id,license,base,media,support_url,contact,title,content,version,origin,developer_id,developer_name,developer_validation,private,confinement,common_ids&q=office&scope=wide:

# Annotation with the search for wps-2019-snap in cache
# jq -r '._embedded."clickindex:package"[]| select( .package_name == "wps-2019-snap" )' $FolderToSaveFilesTmp*

# Download First Page With Applications In Snap Site
curl "https://api.snapcraft.io/api/v1/snaps/search?confinement=strict,classic&fields=architecture,summary,description,package_name,snap_id,title,content,version,common_ids,binary_filesize,license,developer_name,media,&size=200&scope=wide:" >$FolderToSaveFilesTmp/0.json

# Read on the initial page how many pages need to be downloaded and save the value in the variable $NumberOfPages
NumberOfPages="$(jq -r '._links.last.href' $FolderToSaveFilesTmp/0.json | sd '.*&page=' '')"

# Start parallel download of all pages
Page=1
while [ "$Page" -lt "$NumberOfPages" ]; do
    curl "https://api.snapcraft.io/api/v1/snaps/search?confinement=strict,classic&fields=architecture,summary,description,package_name,snap_id,title,content,version,common_ids,binary_filesize,license,developer_name,media,&size=200&scope=wide:&page=$Page" >$FolderToSaveFilesTmp/$Page.json &
    let Page=Page+1
done

# Waiting All Downloads
wait

# Verify if folder $FolderToSaveFilesTmp have more than 10MB
if [ "$(du -m $FolderToSaveFilesTmp | cut -f1)" -le 5 ]; then
    echo "Downloaded file is less than 5MB, which might indicate an error."
    exit 1

else
    rm -f "$FolderToSaveFiles"/*
    mv -f "$FolderToSaveFilesTmp"/* "$FolderToSaveFiles"
fi

# Filter the results of the files and create a cache file that will be used in searches
# jq -r '._embedded."clickindex:package"[]| .title + "|" + .snap_id + "|" + .media[0].url + "|" + .summary + "|" + .version + "|" + .package_name + "|"' $FolderToSaveFiles* | sort -u >$FileToSaveCache
jq -r '._embedded."clickindex:package"[]| .title + "\t" + .summary + "\t" + .package_name + "\t" + .snap_id + "\t" + .version + "\t" + .media[0].url' /home/bruno/.cache/bigstore-cli/snap_list_files/snap_list/* | sd '"' '' | sort -u >$AllSnapCache

# grep -Fwf /usr/share/bigbashview/bcc/apps/big-store/snap_list.txt "$FileToSaveCache" >"$FileToSaveCacheFiltered"
