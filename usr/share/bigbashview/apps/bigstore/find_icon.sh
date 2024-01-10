#!/bin/bash

# Check if the value of the variable 'type' is 'pacman'
if [[ $type = pacman ]]; then

    # Select only the first line from the output of the 'geticons' command with the input 'query'
    while IFS= read -r line; do
        break
    done < <(geticons "$query")

    # Check if the file specified in the 'line' variable exists
    if [[ -e $line ]]; then
        # Print an HTML image tag with the source attribute set to the value of 'line'
        echo "<img class=\"medium\" src=\"$line\" loading=\"lazy\">"
        exit
    fi

    # Check if a specific file exists
    if [[ -e /usr/share/swcatalog/icons/archlinux-arch-extra/64x64/$query\_$query.png ]]; then
        # Print an HTML image tag with the source attribute set to the specific file path
        echo "<img class=\"medium\" src=\"/usr/share/swcatalog/icons/archlinux-arch-extra/64x64/$query\_$query.png\" loading=\"lazy\">"
        exit
    fi

    # Select only the first line from the output of the 'geticons' command with the input 'query' (after removing the hyphen and everything after it)
    while IFS= read -r line; do
        break
    done < <(geticons "${query%%-*}")

    # Check if the file specified in the 'line' variable exists
    if [[ -e $line ]]; then
        # Print an HTML image tag with the source attribute set to the value of 'line'
        echo "<img class=\"medium\" src=\"$line\" loading=\"lazy\">"
        exit
    fi

# Check if the value of the variable 'type' is 'flatpak'
elif [[ $type = flatpak ]]; then

    # Check if a specific file exists
    if [[ -e /var/lib/flatpak/appstream/flathub/x86_64/active/icons/64x64/$query ]]; then
        # Print an HTML image tag with the source attribute set to the specific file path
        echo "<img class=\"medium\" src=\"/var/lib/flatpak/appstream/flathub/x86_64/active/icons/64x64/$query\" loading=\"lazy\">"
        exit
    fi

fi

# Print a default HTML div element with the class "makeIcon" and the first three characters of the 'query' variable as its content
echo "<div class=\"makeIcon\" x-bind:x-on:load=\"makeIcon(\$el)\">${query:0:3}</div>"
