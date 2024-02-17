#!/bin/bash

# Initializes/clean variables to store packages to be installed and removed
pkgs_to_install=""
pkgs_to_remove=""

# Verify if pacman in unlocked, by /var/lib/pacman/db.lck
if [ -f /var/lib/pacman/db.lck ]; then
    # Use fuser to verify if really is in use
    if ! fuser -s /var/lib/pacman/db.lck; then
        rm -f /var/lib/pacman/db.lck
    else
        echo "Pacman is locked by another process"
        ps -f -p $(fuser /var/lib/pacman/db.lck | cut -f2 -d':')
        exit 1
    fi
fi

# Determines the correct version of pactrans to use based on system configuration
if [[ ! -e /usr/share/biglinux/pactrans/bin/pactrans ]] || ldd "/usr/share/biglinux/pactrans/bin/pactrans" | grep -q "=> not found"; then
    pacinstall="pactrans-overwrite-static"
else
   pacinstall="pactrans-overwrite"
fi

# Checks if unbuffer command is available and assigns it to a variable
if [[ -e /usr/bin/unbuffer ]]; then
    unbuffer_cmd='/usr/bin/unbuffer'
fi

# Displays usage help for the script
function show_help() {
    echo "Usage: $0 [options] [...packages]"
    echo "Options:"
    echo "  --install                   Install specified packages"
    echo "  --remove                    Remove specified packages"
    echo "  --upgrade                   Upgrade packages"
    echo "  --reinstall-keys            Reinstalls keyring packages. This process may take a few minutes"
    echo "  --force-reinstall-keys      Caution, this method disables PGP key verification to force install"
    echo "  --json                      Output the transaction in JSON format"
    echo "  --help                      Displays this help message"
    echo ""
    echo "You can combine --install, --remove, and --upgrade in the same execution."
}

# Reinstalls keyring packages
function reinstall_keys {
    # Lists keyring packages and uses awk to extract package names
    key_pkgs="$(LANG=C pacman -Sqi biglinux-keyring manjaro-keyring archlinux-keyring 2> /dev/null | awk -F':' '$1 ~ "^Name " {print $2}')"

    # Reinitialize and repopulate the keyring
    pacman-key --init
    pacman-key --populate
    $pacinstall --dbsync --yolo --overwrite --resolve-replacements=provided --install $key_pkgs 2>&1 | jq -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
}

# Processes script arguments
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            shift # Removes --install from argument list
            while [[ $# -gt 0 ]] && ! [[ "$1" =~ ^-- ]]; do
                pkgs_to_install+="$1 "
                shift
            done
            ;;
        --remove)
            shift # Removes --remove from argument list
            while [[ $# -gt 0 ]] && ! [[ "$1" =~ ^-- ]]; do
                pkgs_to_remove+="$1 "
                shift
            done
            ;;
        --upgrade)
            shift # Removes --upgrade from argument list
            sysupgrade='--sysupgrade'
            ;;
        --json)
            shift # Removes --upgrade from argument list
            output_type='json'
            ;;
        --apply)
            shift # Removes --upgrade from argument list
            apply_in_system='true'
            ;;
        --reinstall-keys)
            reinstall_keys
            exit
            ;;
        --force-reinstall-keys)
            # Disables PGP key verification temporarily to reinstall keys
            sed -Ei 's|SigLevel += +PackageRequired|SigLevel = Never|g' /etc/pacman.conf
            reinstall_keys
            # Restores PGP key verification
            sed -Ei 's|SigLevel += +Never|SigLevel = PackageRequired|g' /etc/pacman.conf
            # Refreshes keys, using Ubuntu's keyserver if necessary
            if [[ $(grep -Ec 'keyserver +hkp' /etc/pacman.d/gnupg/gpg.conf) -lt 2 ]]; then
                pacman-key --refresh-keys -u --keyserver hkp://keyserver.ubuntu.com:80
            else
                pacman-key --refresh-keys
            fi
            exit
            ;;
        --help)
            show_help
            exit
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Remove cascade need claim without install or upgrade, because this we call first remove and sabe in variable
if [ -n "$pkgs_to_remove" ]; then
    remove_pkgs="--remove $(pactrans --print-only --yolo --remove --cascade --recursive $pkgs_to_remove  2>&1 |  awk -F '[ /]+' '/^removing local/ {printf "%s ", $3;}')"
fi

# Performs package installation if necessary
if [ -n "$pkgs_to_install" ]; then
    install_pkgs="--install $pkgs_to_install"
fi

# Create variable with info about transaction, if have error try again with resolve-replacements=provided
echo "Verifying transaction..."
pacinstall_output=$($pacinstall --print-only --dbsync --yolo --overwrite $sysupgrade $install_pkgs $remove_pkgs  2>&1 | tee /var/log/pacman-log-complete.pactrans | jq -Rn -f jq/pactrans.jq | tee /var/log/pacman.json)
if grep -q 'unresolvable package conflicts detected' /var/log/pacman-log-complete.pactrans; then

    use_resolve_replacements='--resolve-replacements=provided'
    pacinstall_output=$( $pacinstall --print-only --yolo --overwrite $use_resolve_replacements $sysupgrade $install_pkgs $remove_pkgs  2>&1 | tee /var/log/pacman-log-complete.pactrans | jq -Rn -f jq/pactrans.jq | tee /var/log/pacman.json)
fi

# This section of code checks if the variable $sysupgrade is empty and if the output of $pacinstall does not contain an error.
# If both conditions are met, it executes $pacinstall with the necessary options and redirects the output to jq for further processing.
if [[ -z $sysupgrade ]] && echo "$pacinstall_output" | grep -q '"type": "error",'; then
    pacinstall_output=$( $pacinstall --print-only --yolo --overwrite $use_resolve_replacements --sysupgrade $install_pkgs $remove_pkgs  2>&1 | tee /var/log/pacman-log-complete.pactrans | jq -Rn -f jq/pactrans.jq )
    sysupgrade='--sysupgrade'
fi

# # Verify if have not locate package error
# not_locate_pkgs=$(awk -F"[:']" '$2 ~ " could not locate package " {print $3}' /var/log/pacman-log-complete.pactrans)
# if [[ -n "$not_locate_pkgs" ]]; then
#     broken_pkgs_without_not_locate=$(paccheck --quiet | grep -Ev '/usr/share/doc|/usr/share/man|/usr/share/wallpapers/|/usr/share/applications/.*.desktop|/usr/lib/libreoffice/share/config/images.*|/usr/share/xsessions/plasma.desktop|/boot/grub/grub.cfg' | cut -f1 -d: | sort -u | tr '\n' ' ')

#     # If install_pkgs variable is not empty, add broken_pkgs_without_not_locate to it, like using if but with parameter expansion
#     install_pkgs=${install_pkgs:+$install_pkgs $broken_pkgs_without_not_locate}
#     # If install_pkgs variable is empty, create it with broken_pkgs_without_not_locate, like using if but with parameter expansion
#     install_pkgs=${install_pkgs:---install $broken_pkgs_without_not_locate}
# fi

# Verify if have missing dependency error
missing_dependency_pkgs=$(awk -F"'" '$1 ~ "error: missing dependency " {printf " " $4}' /var/log/pacman-log-complete.pactrans)
if [[ -n "$missing_dependency_pkgs" ]]; then
    missing_dependency_pkgs_recursive=$($pacinstall --print-only --yolo --overwrite --resolve-replacements=provided --remove --cascade --recursive $missing_dependency_pkgs  2>&1 |  awk -F '[ /]+' '/^removing local/ {printf "%s ", $3;}')

    # If remove_pkgs variable is not empty, add missing_dependency_pkgs_recursive to it, like using if but with parameter expansion
    remove_pkgs=${remove_pkgs:+$remove_pkgs $missing_dependency_pkgs_recursive}
    # If remove_pkgs variable is empty, create it with missing_dependency_pkgs_recursive, like using if but with parameter expansion
    remove_pkgs=${remove_pkgs:---remove $missing_dependency_pkgs_recursive}
fi

# Verify broken_pkgs_without_not_locate and missing_dependency_pkgs_recursive, if one of them is not empty, update pacinstall_output
if [[ -n "$broken_pkgs_without_not_locate" ]] || [[ -n "$missing_dependency_pkgs_recursive" ]]; then
    pacinstall_output=$( $pacinstall --print-only --yolo --overwrite $use_resolve_replacements --sysupgrade $install_pkgs $remove_pkgs  2>&1 | tee /var/log/pacman-log-complete.pactrans | jq -Rn -f jq/pactrans.jq )
fi

if [[ "$apply_in_system" != "true" ]]; then

    if [[ "$output_type" == "json" ]]; then
        echo "$pacinstall_output"
    else
    ##################### CLI OUTPUT START

    # Show general info
    grep -vE '^installing|^removing|^Download Size:|^Installed Size:|^Size Delta:|up to date -- reinstalling' /var/log/pacman-log-complete.pactrans

    # Show info about installing, removing and updating packages
awk -F'[ /()]' '
        $1 == "installing" && $7 != "" && $5 != $7 { print "1 \033[33mupdate \033[0m " $3 " \033[36m" $5 " " $6 " " $7 "|||" $2 }
        $1 == "installing" && $7 != "" && $5 == $7 { print "1 \033[35mreinstall \033[0m" $3 " \033[36m" $5 "|||" $2 }
        $1 == "installing" && $7 == "" { print "2 \033[32minstall\033[0m " $3 " \033[36m" $5 "|||" $2}
        $1 == "removing" { print "3 \033[31mremove \033[0m " $3 " \033[36m" $5 }
    ' /var/log/pacman-log-complete.pactrans | sort | cut -f2- -d" " | column -t -s'|||'

    # Show info about replace and selecting package to solve depends
awk -F"'" '
        $1 == ":: replacing package " && $2 != "" { print "\033[34mreplace \033[0m" $2 "\033[36m with \033[0m" $4 }
        $1 == ":: uninstalling package " && $2 != "" { print "\033[34mreplace \033[0m" $2 "\033[36m with \033[0m" $4}
        $1 == ":: selecting package " && $2 != "" { print "\033[35mselect  \033[0m" $2 " \033[36mto \033[0m" $4}
' /var/log/pacman-log-complete.pactrans | sort

    # Show info about download size, installed size and size delta
    echo -e "\033[0m"
    grep -E '^Download Size:|^Installed Size:|^Size Delta:' /var/log/pacman-log-complete.pactrans

    # Ask user if they want to apply the changes
    echo -e "\033[1;33m"
    echo -en "Do you want to apply these changes to the system? \033[0m (y/n): "
    read -r response

    if [[ "$response" =~ ^[YySs]$ ]]; then
        apply_in_system="true"
    fi

    ##################### CLI OUTPUT END
    fi
fi

# Apply the transaction in the system CLI
if [[ "$apply_in_system" == "true" ]] && [[ "$output_type" != "json" ]]; then
    # It ensures that key packages are installed before other upgrades and checks if there are any key packages to upgrade.
    sync_first=$(pacman -Quq $(awk -F'=' '$1 ~ "^ *SyncFirst" {print $2}'  /etc/pacman.conf) 2>&- | tr '\n' ' ')
    if [ -n "$sync_first" ]; then
         $pacinstall --yolo --overwrite --resolve-replacements=provided --install $sync_first 2>&1 | tee /var/log/pacman-log-complete.pactrans
    fi

    if [[ -n "$use_resolve_replacements" ]]; then

        # Upgrade or installation processes
         $pacinstall --yolo --overwrite --resolve-replacements=provided $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans

        # Run another time without resolve-replacements=provided
         $pacinstall --yolo --overwrite $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans

    else
        # Run without resolve-replacements=provided
         $pacinstall --yolo --overwrite $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans
    fi
fi

# Apply the transaction in the system JSON
if [[ "$apply_in_system" == "true" ]] && [[ "$output_type" != "json" ]]; then
    # It ensures that key packages are installed before other upgrades and checks if there are any key packages to upgrade.
    sync_first=$(pacman -Quq $(awk -F'=' '$1 ~ "^ *SyncFirst" {print $2}'  /etc/pacman.conf) 2>&- | tr '\n' ' ')
    if [ -n "$sync_first" ]; then
        $unbuffer $pacinstall --yolo --overwrite --resolve-replacements=provided --install $sync_first 2>&1 | tee /var/log/pacman-log-complete.pactrans | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
    fi

    if [[ -n "$use_resolve_replacements" ]]; then

        # Upgrade or installation processes
        $unbuffer $pacinstall --yolo --overwrite --resolve-replacements=provided $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json

        # Run another time without resolve-replacements=provided
        $unbuffer $pacinstall --yolo --overwrite $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json

    else
        # Run without resolve-replacements=provided
        $unbuffer $pacinstall --yolo --overwrite $sysupgrade $install_pkgs $remove_pkgs 2>&1 | tee /var/log/pacman-log-complete.pactrans | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
    fi
fi



# Verify key error and try reinstall
if grep -q 'could not be looked up remotely key' /var/log/pacman-log-complete.pactrans; then
    reinstall_keys
fi
