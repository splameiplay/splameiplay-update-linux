#!/bin/bash

set -euo pipefail

echo "--- SplameiPlay Uninstaller (Linux) ---"
echo "By Splamei"
echo "Version: 1.0.0.0"
echo

INSTALL_LOG_FILE="/var/log/splameiplay-install-files.log"
UPDATE_SCRIPT_LOCATION="/usr/bin/splameiplay-update"

SAFE_EMPTY_DIRS=(
    "/opt/splameiplay"
    "/usr/share/doc/splameiplay"
)

printLineLimit()
{
	COLS=$(tput cols)
	local text="$1"
	local max_len=$(( COLS - 4 ))

	if [ ${#text} -gt $max_len ]; then
        text="${text:0:$max_len}..."
    fi

    echo -ne "\r\033[2K$text"
}

removeFiles()
{
    for file in "${DELETE_CONTENT_FILES[@]}"; do
        [[ -z "$file" || "$file" =~ ^[[:space:]]*# ]] && continue

        if [[ ! -e "$file" ]]; then
            printLineLimit "  - Skipping file (not found) '$file'"
            continue
        fi

        if [[ "$file" == /usr/* || "$file" == /opt/* ]]; then
            printLineLimit "  - Removing file as root '$file'"
            sudo rm -f -- "$file"
        else
            printLineLimit "  - Removing file '$file'"
            rm -f -- "$file"
        fi
    
    done

    for dir in "${SAFE_EMPTY_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            if [[ "$dir" == /usr/* || "$dir" == /opt/* ]]; then
                printLineLimit "  - Removing dir as root '$dir'"
                sudo rmdir -p --ignore-fail-on-non-empty "$dir" 2>/dev/null || true
            else
                printLineLimit "  - Removing dir '$dir'"
                rmdir -p --ignore-fail-on-non-empty "$dir" 2>/dev/null || true
            fi
        fi
    done
}

main()
{
    CAN_REMOVE="0"

    if [[ ! -e "$INSTALL_LOG_FILE" ]]; then
        echo "ERR: The install log file used by SplameiPlay (Linux) to track installed files couldn't be found so we can't remove anything"
        echo " - It may be deleted by another user or process"
        echo " - For more information, please contact us for support or look at our documentation website https://docs.veemo.uk"
        exit 1
    fi

    echo "You're about to remove SplameiPlay from your device"
    echo "Are you sure you want to continue?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) CAN_REMOVE="1"; break;;
            No ) break;;
        esac
    done

    echo

    if [ $CAN_REMOVE == "0" ]; then
        echo "Okay. No changes were made"
        exit 0
    fi

    CAN_REMOVE="0"
    mapfile -t DELETE_CONTENT_FILES < "$INSTALL_LOG_FILE"

    echo "--------------------" 

    for file in "${DELETE_CONTENT_FILES[@]}"; do
        echo "$file"
    done

    echo "--------------------"
    echo
    echo "We're about to delete the following files. Do you still want to continue?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) CAN_REMOVE="1"; break;;
            No ) break;;
        esac
    done

    echo
    if [ $CAN_REMOVE == "0" ]; then
        echo "Okay. No changes were made"
        exit 0
    fi

    echo "- Removing SplameiPlay"

    sudo -v
    removeFiles

    printLineLimit "  - Done!"
    echo
    echo "- Cleaning up"
    sudo rm "$INSTALL_LOG_FILE"
    sudo rm "$UPDATE_SCRIPT_LOCATION"

    sudo update-desktop-database || true
    sudo gtk-update-icon-cache /usr/share/icons/hicolor || true
    sudo xdg-mime default splameiplay.desktop x-scheme-handler/splameiplay || true

    sudo update-mime-database /usr/share/mime
    sudo xdg-mime default splameiplay.desktop application/splameiplay
    sudo xdg-mime default splameiplay.desktop application/spinstaller
    sudo xdg-mime default splameiplay.desktop application/sptheme
    
    echo
    echo "-------------------------------------------------"
    echo
    echo "  SplameiPlay has been removed from your device"
    echo
    echo "  Thank you for using SplameiPlay"
    echo "  ~ Splamei"
    echo
    echo "-------------------------------------------------"
    echo

    echo "To fully remove SplameiPlay, it's best you reboot your system so the changes can take effect"
}

main