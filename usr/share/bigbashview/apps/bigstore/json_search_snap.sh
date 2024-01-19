#!/bin/bash
##################################
#  Author Create: Bruno Gonçalves (www.biglinux.com.br) 
#  Author Modify: Rafael Ruscher (rruscher@gmail.com)
#  Create Date:    2020/01/11
#  Modify Date:    2022/05/09 
#  
#  Description: Big Store installing programs for BigLinux
#  
#  Licensed by GPL V2 or greater
##################################


if [[ "$(systemctl is-active snapd)" != "active" ]]; then
    exit 0
fi

# Folder to save list of packages
CacheFiles="snap_list"
FolderToSaveFiles="$HOME/.cache/bigstore/snap_list_files/"
FileToSaveCache="$HOME/.cache/bigstore/snap.cache"
FileToSaveCacheFiltered="$HOME/.cache/bigstore/snap_filtered.cache"


if [[ ! -e $FileToSaveCacheFiltered ]]; then
    rm -rf "$FolderToSaveFiles"
    mkdir -p "$FolderToSaveFiles"

    # Download first page with applications from the snap site
    curl "https://api.snapcraft.io/api/v1/snaps/search?confinement=strict&fields=architecture,summary,description,package_name,snap_id,title,content,version,common_ids,binary_filesize,license,developer_name,media,&scope=wide:" > "$FolderToSaveFiles/$CacheFiles"

    # Read total pages needed to download
    NumberOfPages="$(jaq -r '._links.last' "$FolderToSaveFiles/$CacheFiles" | sed 's|.*page=||g;s|"||g' | grep [0-9])"

    # Loop to download all pages
    Page=2
    while [ "${Page}" -lt "$NumberOfPages" ]; do
        echo "Downloading $Page of $NumberOfPages"
        curl "https://api.snapcraft.io/api/v1/snaps/search?confinement=strict,classic&fields=architecture,summary,description,package_name,snap_id,title,content,version,common_ids,binary_filesize,license,developer_name,media,&scope=wide:&page=$Page" >> "$FolderToSaveFiles$Page" &
        ((Page++))
    done

    # Wait for all downloads to complete
    wait

    # Filtering files and create cache file for the searching system
    jaq . "$FolderToSaveFiles"/* > "$FileToSaveCache"
    jaq -c '[._embedded."clickindex:package"[] | select(.architecture[] | contains("amd64")) | {g: (if .media then .media | map(select(.type == "icon"))[0].url else null end), v: .version, d: .summary, n: .snap_id, p: .title, k: .package_name}]' "$FileToSaveCache" > "$FileToSaveCacheFiltered"
    sd '\]\n\[' ',' "$FileToSaveCacheFiltered"
fi

cat "$FileToSaveCacheFiltered"
