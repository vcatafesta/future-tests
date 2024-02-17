#!/usr/bin/env bash

if ldd "/usr/share/biglinux/pactrans/bin/pactrans" | grep -q "=> not found"; then
    pacinstall="pactrans-overwrite-static"
else
    pacinstall="pactrans-overwrite"
fi

# Initializing variables
declare -a install_packages
declare -a remove_packages
update_system=false
no_deps_version=false
no_deps=false
yolo=false
dbsync=false
overwrite=false
print_only=false

# Function to display help message
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --install <package1> <package2> ...    Install multiple packages."
    echo "  --remove <package1> <package2> ...     Remove multiple packages."
    echo "  --update                               Update the system."
    echo "  --no-deps-version                      Option to skip specific version dependencies (if applicable)."
    echo "  --no-deps                              Install or remove packages without installing dependencies."
    echo "  --overwrite                            Overwrite files without asking."
    echo ""
    echo "Example:"
    echo "  $0 --install package1 package2 --remove package3 package4 --update --no-deps"
}

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --install)
            shift # Move past the '--install' argument
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                install_packages+=("$1") # Add the package to the installation list
                shift # Move to the next package
            done
            continue
            ;;
        --remove)
            shift # Move past the '--remove' argument
            while [[ $# -gt 0 && ! $1 =~ ^-- ]]; do
                remove_packages+=("$1") # Add the package to the removal list
                shift # Move to the next package
            done
            continue
            ;;
        --update)
            update_system=true
            ;;
        --no-deps-version)
            no_deps_version=true
            ;;
        --no-deps)
            no_deps=true
            ;;
        --overwrite)
            overwrite=true
            ;;
        --dbsync)
            dbsync=true
            ;;
        --print-only)
            print_only=true
            ;;
        --yolo)
            yolo=true
            ;;
        *)
            echo "Unknown option: $key"
            show_help
            exit 1
            ;;
    esac
    shift # Move past the current argument
done

# Processing the collected options
if [[ ${#install_packages[@]} -gt 0 ]]; then
    echo "Installing packages: ${install_packages[*]}"
    # Here you would put the actual installation command with options
fi

if [[ ${#remove_packages[@]} -gt 0 ]]; then
    echo "Removing packages: ${remove_packages[*]}"
    # Here you would put the actual removal command
fi

if [[ "$update_system" = true ]]; then
    echo "Updating system"
    # Actual update command
fi

if [[ "$no_deps" = true ]]; then
    echo "Installation/removal will be performed without dependencies"
fi

if [[ "$overwrite" = true ]]; then
    echo "Overwrite option activated"
fi




# Resolver problema de chave:

# sudo pactrans-overwrite --yolo --resolve-replacements=provided --dbsync --overwrite --install manjaro-system archlinux-keyring manjaro-keyring biglinux-keyring

# Atualizar o sistema

# sudo pactrans-overwrite --yolo --resolve-replacements=provided --dbsync --overwrite --sysupgrade
# Concluir a atualização

# sudo pactrans-overwrite --yolo --dbsync --overwrite --sysupgrade
