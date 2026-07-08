#!/bin/bash

ARGS="$#"
ARG_0="$0"
ARG_1="${1:-N/A}"
ARG_2="${2:-N/A}"

set -eu

echo "--- SplameiPlay Update (Linux) ---"
echo "By Splamei"
echo "Version: 1.0.0.0"
echo

VERSION_CODE="1000"
FLOW_VERSION="1.2"

MY_VERSION_URL="https://www.veemo.uk/flow/$FLOW_VERSION/splameiplay/update/linux/version"

FILES_DOWNLOAD_URL="https://www.veemo.uk/flow/$FLOW_VERSION/splameiplay/update/linux/app/CHANNEL/data.zip"
FILES_DOWNLOAD_SIG_URL="https://www.veemo.uk/flow/$FLOW_VERSION/splameiplay/update/linux/app/CHANNEL/data.zip.sig"

FILES_DOWNLOAD_LOCATION="/tmp/splameiplayData.zip"
FILES_DOWNLOAD_SIG_LOCATION="/tmp/splameiplayData.zip.sig"

FILES_EXTRACTED_TEMP_LOCATION="/tmp/splameiplay-data"
FILES_EXTRACTED_DATA_PATH="/tmp/splameiplay-data/DATA"
FILES_EXTRACTED_POSTINST_PATH="/tmp/splameiplay-data/CONTROL/POSTINST"

VERSION_FILE_LOCATION="/etc/splamei/splameiplay/launcher/updater-data/updateVer.dat"
RELEASE_CHANNEL_FILE_LOCATION="/etc/splamei/splameiplay/launcher/updater-data/channelType.dat"
RELEASE_CHANNEL_FILE_DIR="/etc/splamei/splameiplay/launcher/updater-data/"

INSTALL_LOG_FILE="/var/log/splameiplay-install-files.log"

TMP_SIG_LOCATION="/tmp/splameiplay_sig.bin"

PUBLIC_SIGN='-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtLk342/efLv03RWAlh2/
rwiR7fHyp6pdodNFJMi8+TL9es3FxDr3U/fzk46vuVxgiZCnFfKBVIpLx3JloReg
HHrm6b5PlYokYlQQPrYffAf9JDTOKYdGHXa25nJEKwJvtNrwbE478VrJJlTbdrwx
QY0SsS7xEGEvK2UzoVFKe6yuRHDHGXQcgnmJzhQaip3Fowa6vQkrrUUAujUzresI
QwZavuWyyWbNfN1kiOT6ABB26ymXhrNnlUT9SvRAhitFetK9TXCm5czWj9B37/my
GyDuZtOXrwCfLrxLG36Ww8nQrjXWZCDbrNSh7erNeItZOkyGo2xgeeMvZ2EibWNu
PT50xirabZ5gdrH20YyQbX/GCqMt7RrML9ZTE8BHAl9nqnK8O7ape3z0VLnbBJCQ
uKVMvJRtJTxHxQjYIrRbhWV1yWkmgMOyXW41UN7e3xO+3FdpgUmv3bX5ShU6eN+b
NeibxXxMjsP1Pk3xsZZFDUmvttsVe3TTwQ9WTmImLQNljhQMY+gzet+uSI7Jm4P2
a7coBGYj6Bc2JQ5l1nQ40qNmPkojty9XU3KEF0xXpRLFmRTUC53C0aDsw2EDe5CZ
xIWqqjSxYruG+jmSljEpAcME8W2dnp1JtijqOTMwvZeN3baRNEqXmMRK/Xn/DuMy
x0XVyrcikaD16caU3vBOlZMCAwEAAQ==
-----END PUBLIC KEY-----'

verifySig()
{
	echo "$2" >> "/tmp/tmp.dat"

	# par 1: sig - par 2: public - par 3: file
	openssl base64 -d -A -in "$1" -out "$TMP_SIG_LOCATION"
	if openssl dgst -sha256 -verify "/tmp/tmp.dat" -signature "$TMP_SIG_LOCATION" "$3" >/dev/null 2>&1; then
		return 0
	else
		return 1
	fi
}

logFileLocation()
{
    local TARGET_PATH="$1"
    [ -z "$TARGET_PATH" ] && return

    if ! sudo grep -qFx "$TARGET_PATH" "$INSTALL_LOG_FILE" 2>/dev/null; then
        echo "$TARGET_PATH" | sudo tee -a "$INSTALL_LOG_FILE" >/dev/null
    fi
}

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

checkSystem()
{
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    if [ $OS != "Linux" ]; then
        echo "ERR: SplameiPlay doesn't support your platform. Platform: $OS"
        echo " - For more information, please vist our documentation website (https://docs.veemo.uk) or contact us for support"
        exit 1
    elif [ $ARCH != "x86_64" ]; then
        echo "ERR: SplameiPlay doesn't support your device's architecture. Platform: $ARCH"
        echo " - For more information, please vist our documentation website (https://docs.veemo.uk) or contact us for support"
        exit 1
    fi
}

updateApp()
{
    if [ ! -f "$RELEASE_CHANNEL_FILE_LOCATION" ]; then
        sudo mkdir -p "$RELEASE_CHANNEL_FILE_DIR"
        sudo chmod 755 "$RELEASE_CHANNEL_FILE_DIR"

        sudo bash -c 'echo "0" > "$1"' _ "$RELEASE_CHANNEL_FILE_LOCATION"
        sudo chmod 666 "$RELEASE_CHANNEL_FILE_LOCATION"
        echo "No release channel set! Defaulting to 'Stable'"
    fi

    RELEASE_CHANNEL_FILE=$(< "$RELEASE_CHANNEL_FILE_LOCATION")
    RELEASE_CHANNEL="stable"

    if [ "$RELEASE_CHANNEL_FILE" == "1" ]; then
        RELEASE_CHANNEL="beta"
    elif [ "$RELEASE_CHANNEL_FILE" == "2" ]; then
        RELEASE_CHANNEL="alpha"
    fi

    FILES_DOWNLOAD_URL="${FILES_DOWNLOAD_URL/CHANNEL/$RELEASE_CHANNEL}"
    FILES_DOWNLOAD_SIG_URL="${FILES_DOWNLOAD_SIG_URL/CHANNEL/$RELEASE_CHANNEL}"

    echo "Release channel: $RELEASE_CHANNEL"
    echo

    sudo bash -c 'echo "$2" > "$1"' _ "$VERSION_FILE_LOCATION" "$VERSION_CODE"
    sudo chmod 755 "$VERSION_FILE_LOCATION"

    if which curl >/dev/null 2>&1; then
        echo "- Downloading SplameiPlay"
        echo

        curl -fSL "$FILES_DOWNLOAD_URL" -o "$FILES_DOWNLOAD_LOCATION"
        curl -fsSL "$FILES_DOWNLOAD_SIG_URL" -o "$FILES_DOWNLOAD_SIG_LOCATION"

        set +e
        echo
        echo "- Verifing the download"
        verifySig "$FILES_DOWNLOAD_SIG_LOCATION" "$PUBLIC_SIGN" "$FILES_DOWNLOAD_LOCATION"

        if [ $? -eq 0 ]; then
            set -e

            echo "- Starting to install SplameiPlay"

            rm "$FILES_DOWNLOAD_SIG_LOCATION"
            rm "$TMP_SIG_LOCATION"

            unzip -o -d "$FILES_EXTRACTED_TEMP_LOCATION" "$FILES_DOWNLOAD_LOCATION" >/dev/null 2>&1

            rm "$FILES_DOWNLOAD_LOCATION"

            echo "- Installing SplameiPlay"

            sudo -v

            find "$FILES_EXTRACTED_DATA_PATH" -type f | while IFS= read -r f; do
                rel="${f#"$FILES_EXTRACTED_DATA_PATH"/}"
                target="/$rel"

                #echo "  - Installing '$f' to '$target'"
                #echo -ne "\r\033[2K  - Installing '$target'"
                printLineLimit "  - Installing '$target'"

                sudo mkdir -p "$(dirname "$target")"
                sudo cp -p "$f" "$target"

                logFileLocation "$target"
            done

            echo -ne "\r\033[2K"
            echo "  - Done!"

            echo "- Configuring SplameiPlay"
            echo "  - You're almost done with the update. Just a little more to go"

            chmod +x "$FILES_EXTRACTED_POSTINST_PATH"
            "$FILES_EXTRACTED_POSTINST_PATH"

            echo "- Cleaning up"

            rm -r "$FILES_EXTRACTED_TEMP_LOCATION"

            echo
            echo "------------------------------------------------------------------------"
            echo
            echo "         SplameiPlay has been installed and is ready for use!"
            echo "You can launch SplameiPlay via the app menu or the command 'splameiplay'"
            echo
            echo "                 Thank you for choosing SplameiPlay!"
            echo
            echo "------------------------------------------------------------------------"
        else
            set -e

            echo
			echo "ERR: Something went wrong when installing SplameiPlay. Please try again later or contact us for support"
			echo " - Failed to validate downloaded files"

            rm "$FILES_DOWNLOAD_SIG_LOCATION"
			rm "$FILES_DOWNLOAD_LOCATION"
			rm "$TMP_SIG_LOCATION"

            exit 1
        fi

        set -e
    else
        echo "ERR: To install SplameiPlay, you need to install curl to your system so we can download the latest version and required files. Please install curl then try again"
		echo "For Debian/Ubuntu based systems, you can install curl via 'sudo apt install curl'"
		exit 1
    fi


}

main()
{
    if [[ $EUID -eq 0 ]]; then
		echo "ERR: You cannot run this as root! Please re-run this command as a normal user"
		echo "- NOTE: Some operations needed to install/update SplameiPlay will require sudo permissions"

		exit 1
	fi

    checkSystem

    if [ "$ARGS" -eq 0 ]; then
        SERVER_VER_CODE=$(curl -fsSL "$MY_VERSION_URL")
        if [[ "$SERVER_VER_CODE" == "$VERSION_CODE" ]]; then
            updateApp
        else
            echo "ERR: There's a new update to SplameiPlay Update (Linux). Please update this to continue to update SplameiPlay"
            echo "You can update this using the following command or visiting https://www.veemo.uk/splameiplay/download"
            echo " - 'curl https://www.veemo.uk/flow/1.2/splameiplay/update/linux/install.sh | bash'"
            exit 1
        fi
    else
        if [ "$ARG_1" == "channel" ]; then
            if [ "$ARGS" -eq 2 ]; then
                sudo mkdir -p "$RELEASE_CHANNEL_FILE_DIR"
                sudo chmod 755 "$RELEASE_CHANNEL_FILE_DIR"

                if [ "$ARG_2" == "stable" ]; then
                    sudo bash -c 'echo "0" > "$1"' _ "$RELEASE_CHANNEL_FILE_LOCATION"
                    echo "Changed the release channel to the Stable channel"
                elif [ "$ARG_2" == "beta" ]; then
                    sudo bash -c 'echo "1" > "$1"' _ "$RELEASE_CHANNEL_FILE_LOCATION"
                    echo "Changed the release channel to the Beta channel"
                elif [ "$ARG_2" == "alpha" ]; then
                    sudo bash -c 'echo "2" > "$1"' _ "$RELEASE_CHANNEL_FILE_LOCATION"
                    echo "Changed the release channel to the Alpha channel"
                else
                    echo "Unknown release channel. The only valid channels are 'stable', 'alpha' or 'beta' (case sensitive)"
                    echo "For more information, please read the official documantation https://docs.veemo.uk"

                    exit 1
                fi

                sudo chmod 666 "$RELEASE_CHANNEL_FILE_LOCATION"
            else
                echo "To change the channel, run the command '$ARG_0 channel <channel>'"
                echo "For more information, please read the official documantation https://docs.veemo.uk"

                exit 1
            fi
        elif [ "$ARG_1" == "help" ]; then
            echo "Learn about how to use SplameiPlay and SplameiPlay Update for Linux on the official documentation website - https://docs.veemo.uk"
        else
            echo "Unknown argument. Run the command with either no arguments to update SplameiPlay or '$ARG_0 channel <channel>' to change the channel"
            echo "For more information, please read the official documantation https://docs.veemo.uk"

            exit 1
        fi
    fi
}

main