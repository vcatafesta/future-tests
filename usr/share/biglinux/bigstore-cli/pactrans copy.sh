#!/bin/bash

# Inicializa as variáveis para armazenar pacotes a serem instalados e removidos
pkgs_to_install=""
pkgs_to_remove=""

if ldd "/usr/share/biglinux/pactrans/bin/pactrans" | grep -q "=> not found"; then
     pacinstall="pactrans-overwrite-static"
else
   pacinstall="pactrans-overwrite"
fi

if [[ -e /usr/bin/unbuffer ]]; then

    unbuffer='unbuffer'
fi

# Função para exibir ajuda
function show_help() {
    echo "Uso: $0 [opções] [...pacotes]"
    echo "Opções:"
    echo "  --install               Instala os pacotes especificados"
    echo "  --remove                Remove os pacotes especificados"
    echo "  --upgrade"
    echo "  --force-upgrade"        
    echo "  --reinstall-keys        This process may take a few minutes"
    echo "  --force-reinstall-keys  Caution, this method disable PGP key verification of key packages to force install"
    echo "  --help                  Exibe esta ajuda"
    echo "Você pode combinar --install, --remove e --upgrade na mesma execução."
}

function reinstall_keys {
    # Show available keyring packages in repositories and use awk to filter lines started with Name and use field separator as : and show $2, because is package name
    key_pkgs="$(LANG=C pacman -Sqi biglinux-keyring manjaro-keyring archlinux-keyring 2> /dev/null | awk -F':' '$1 ~ "^Name " {printf $2}')"

    # Remove actual keys
#     mv -f /etc/pacman.d/gnupg /etc/pacman.d/gnupg-bkp

    # Reinstall keys
    pacman-key --init
    pacman-key --populate
    $pacinstall --dbsync --yolo --overwrite --resolve-replacements=provided --install $key_pkgs 2>&1 | jq -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
}

function force_upgrade {
    broken_pkgs=$(sudo paccheck --quiet | grep -Ev '/usr/share/doc|/usr/share/man|/usr/share/wallpapers/|/usr/share/applications/.*.desktop|/usr/lib/libreoffice/share/config/images.*|/usr/share/xsessions/plasma.desktop|/boot/grub/grub.cfg' | cut -f1 -d: | sort -u | tr '\n' ' ')

    # Verify if have erros to try reinstall broken packages
    if ! $pacinstall --dbsync --yolo --overwrite --resolve-replacements=provided --sysupgrade --print-only --install $broken_pkgs 2> /var/log/pactrans.error; then

        # If not have errors, just reinstall
        $pacinstall --yolo --overwrite --resolve-replacements=provided --sysupgrade --install $broken_pkgs

    else

        not_locate_pkgs=$(awk -F"[:']" '$2 ~ " could not locate package " {print $3}' /var/log/pactrans.error)
        broken_pkgs_without_not_locate=$(echo "$broken_pkgs" | tr ' ' '\n' | grep -vFf <(echo "$not_locate_pkgs") | tr '\n' ' ') | tr '\n' ' ')

        # Detect packages needed to remove
        missing_dependency_pkgs=$(awk -F"'" '$1 ~ "error: missing dependency " {printf " " $4}' /var/log/pactrans.error)
        missing_dependency_pkgs_recursive=$($pacinstall --print-only --yolo --overwrite --resolve-replacements=provided --remove --cascade --recursive $missing_dependency_pkgs  2>&1 |  awk -F '[ /]+' '/^removing local/ {printf "%s ", $3;}')

        # If upgrade packages without not locate without need remove packages manually
        $pacinstall --yolo --overwrite --resolve-replacements=provided --sysupgrade --remove $missing_dependency_pkgs_recursive --install $broken_pkgs_without_not_locate
        $pacinstall --yolo --overwrite --resolve-replacements=provided --sysupgrade 2>&1 | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json

    fi
}

# Verifica se algum argumento foi fornecido
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Processa os argumentos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --install)
            shift # Remove --install da lista de argumentos
            while [[ $# -gt 0 ]] && ! [[ "$1" =~ ^-- ]]; do
                pkgs_to_install+="$1 "
                shift
            done
            ;;
        --remove)
            shift # Remove --remove da lista de argumentos
            while [[ $# -gt 0 ]] && ! [[ "$1" =~ ^-- ]]; do
                pkgs_to_remove+="$1 "
                shift
            done
            ;;
        --upgrade)
            shift # Remove --upgrade da lista de argumentos
            sysupgrade='--sysupgrade'
            ;;
        --reinstall-keys)
            reinstall_keys
            exit
            ;;
        --force-upgrade)
            force_upgrade
            exit
            ;;
        --force-reinstall-keys)
            sed -Ei 's|SigLevel += +PackageRequired|SigLevel = Never|g' /etc/pacman.conf
            reinstall_keys
            sed -Ei 's|SigLevel += +Never|SigLevel = PackageRequired|g' /etc/pacman.conf
            # Verify number of gpg servers, if have less than 2 force to use ubuntu server
            if [[ $(grep -Ec 'keyserver +hkp' /etc/pacman.d/gnupg/gpg.conf) -gt 2 ]]; then
                pacman-key --refresh-keys
            else
                pacman-key --refresh-keys -u --keyserver hkp://keyserver.ubuntu.com:80
            fi
            exit
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Executa a remoção de pacotes, se necessário
if [ -n "$pkgs_to_remove" ]; then
    remove_pkgs="--remove $(pactrans --print-only --yolo --overwrite --resolve-replacements=provided --remove --cascade --recursive $pkgs_to_remove  2>&1 |  awk -F '[ /]+' '/^removing local/ {printf "%s ", $3;}')"
fi

# Executa a instalação de pacotes, se necessário
if [ -n "$pkgs_to_install" ] || [ -n "$remove_pkgs" ]; then
    install_pkgs="--install $pkgs_to_install"
fi

# Test command
pacinstall_output=$( $pacinstall --print-only --dbsync --yolo --overwrite --resolve-replacements=provided $sysupgrade $install_pkgs $remove_pkgs  2>&1 | jq -Rn -f jq/pactrans.jq )


# Verify if have error in output if not have sysupgrade, and try with sysupgrade
if [[ -z $sysupgrade ]] && ! echo "$pacinstall_output" | grep -q '"type: "error",'; then

    pacinstall_output_with_upgrade=$( $pacinstall --print-only --yolo --overwrite --resolve-replacements=provided --sysupgrade $install_pkgs $remove_pkgs  2>&1 | jq -Rn -f jq/pactrans.jq )

    if ! echo "$pacinstall_output_with_upgrade" | grep -q '"type: "error",'; then
        echo "Need upgrade system to install"
        exit 1
    else
        echo "Install without sysupgrade was successful"
        exit 0
    fi
fi

# Verify if need upgrade First sync ( Generally only keyring packages )
sync_first=$(pacman -Quq $(awk -F'=' '$1 ~ "^ *SyncFirst" {print $2}'  /etc/pacman.conf) 2>&- | tr '\n' ' ')

if [ -n "$sync_first" ]; then
    $unbuffer $pacinstall --yolo --overwrite --import-pgp-keys=yes --resolve-replacements=provided --install $sync_first 2>&1 | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
fi

$unbuffer $pacinstall --yolo --overwrite --import-pgp-keys=yes --resolve-replacements=provided $sysupgrade $install_pkgs $remove_pkgs 2>&1 | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json

# If upgrading system, verify if need more updates
if [ -n "$sysupgrade" ]; then
    $unbuffer $pacinstall --dbsync --yolo --overwrite --import-pgp-keys=yes $sysupgrade $install_pkgs $remove_pkgs 2>&1 | jq --unbuffered -Rn -f jq/pactrans.jq | tee /var/log/pacman.json
fi



# Verify key error and try reinstall
if grep -q '"error": "could not be looked up remotely key"' /var/log/pacman.json; then
    reinstall_keys
fi
