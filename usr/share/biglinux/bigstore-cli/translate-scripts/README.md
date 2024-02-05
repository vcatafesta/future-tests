# Bigstore Translate Scripts

This repository contains a collection of scripts designed to automate the translation of package summaries and descriptions for various package management systems and software distribution services, including AUR, Flatpak, Pacman, and Snap, as well as for Flathub and AppStream content. Each script is tailored for its specific target, with intelligent features to streamline the translation process.

## Scripts Overview

### AUR (Arch User Repository), Flatpak, Pacman, and Snap

- `translate-aur.sh`, `translate-flatpak.sh`, `translate-pacman.sh`, `translate-snap.sh`: Translates the summary of packages or applications to a specified language. These scripts check what has already been translated in previous runs, ensuring only new or missing summaries are translated.

- `translate-aur-all.sh`, `translate-flatpak-all.sh`, `translate-pacman-all.sh`, `translate-snap-all.sh`: These scripts extend the functionality to translate summaries for all packages or applications into multiple languages, also checking for previously translated content to avoid duplication.


### Flathub and AppStream

- `flathub-translate.sh`, `appstream-translate.sh`: Translates the detailed descriptions of applications. Unlike the package management scripts, these do not check for previously translated content themselves. Instead, they examine the AppStream and Flathub XML files for existing translations and automate the translation of content not already translated by the AppStream and Flathub projects. If executed again, these scripts will redo all automatic translations, regardless of previous runs.

- `translate-appstream-extra-to-all-languages.sh`, `translate-appstream-flathub-to-all-languages.sh`: Translates additional content for all languages, applying the same logic of not checking for previously automated translations but using existing translations from the projects.


### AppStream XML to JSON Conversion

- `appstream-xml-to-json-filtered-by-lang.sh`, `appstream-xml-flatpak-to-json-filtered-by-lang.sh`: These scripts convert AppStream XML metadata into JSON format, filtering the content by a specified language and incorporating any existing translations found within the AppStream and Flatpak XML files.


## Usage

Each script is designed for command-line execution. Specific parameters, such as the target language for translations, may be required. For detailed instructions, refer to the comments within each script file.


## Requirements

- Bash shell, jq, sd, sed, trans
- Command-line tools for interacting with each package management system
- Internet access for accessing translation services


## Contributing

Contributions to improve or enhance the scripts are highly appreciated. Please feel free to open a pull request with your changes.
