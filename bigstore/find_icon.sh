#!/bin/bash


if [[ $type = pacman ]]; then

    # Select only first line
    while IFS= read -r line; do
        break
    done < <(geticons "$query")

    if [[ -e $line ]]; then
        echo "<img class=\"medium\" src=\"$line\" loading=\"lazy\">"
        exit
    fi
    if [[ -e /usr/share/swcatalog/icons/archlinux-arch-extra/64x64/${query}_$query.png ]]; then
        echo "<img class=\"medium\" src=\"/usr/share/swcatalog/icons/archlinux-arch-extra/64x64/${query}_$query.png\" loading=\"lazy\">"
        exit
    fi

    while IFS= read -r line; do
        break
    done < <(geticons "${query%%-*}")
    if [[ -e $line ]]; then
        echo "<img class=\"medium\" src=\"$line\" loading=\"lazy\">"
        exit
    fi

    

elif [[ $type = flatpak ]]; then

    if [[ -e /var/lib/flatpak/appstream/flathub/x86_64/active/icons/64x64/$query ]]; then
        echo "<img class=\"medium\" src=\"/var/lib/flatpak/appstream/flathub/x86_64/active/icons/64x64/$query\" loading=\"lazy\">"
        exit
    fi

fi

echo "<div class=\"makeIcon\" x-bind:x-on:load=\"makeIcon(\$el)\">${query:0:3}</div>"
