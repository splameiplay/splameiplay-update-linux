#!/bin/bash
set -eu

echo "--- SplameiPlay ---"
echo "By Splamei"
echo

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

FLOW_VERSION="1.2"

DOWNLOAD_SCRIPT_LOCATION="https://www.veemo.uk/flow/$FLOW_VERSION/splameiplay/update/linux/command/update.sh"
DOWNLOAD_SCRIPT_SIG_LOCATION="https://www.veemo.uk/flow/$FLOW_VERSION/splameiplay/update/linux/command/update.sh.sig"

SCRIPT_TMP_LOCATION="/tmp/splameiplayInstall.sh"
SCRIPT_TMP_SIG_LOCATION="/tmp/splameiplayInstall.sh.sig"

TMP_SIG_LOCATION="/tmp/splameiplay_sig.bin"

SCRIPT_FINAL_DEST="/usr/bin/splameiplay-update"

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

main()
{
	checkSystem

	if [[ $EUID -eq 0 ]]; then
		echo "ERR: You cannot run this as root! Please re-run the command as a normal user"
		echo "- NOTE: Some operations needed to install SplameiPlay will require sudo permissions"

		exit 1
	fi

	if which curl >/dev/null 2>&1; then
		echo "- Downloading SplameiPlay Update (Linux)"

		curl -fsSL $DOWNLOAD_SCRIPT_LOCATION -o $SCRIPT_TMP_LOCATION
		curl -fsSL $DOWNLOAD_SCRIPT_SIG_LOCATION -o $SCRIPT_TMP_SIG_LOCATION

		set +e
		echo "- Verifying the download"
		verifySig "$SCRIPT_TMP_SIG_LOCATION" "$PUBLIC_SIGN" "$SCRIPT_TMP_LOCATION"

		if [ $? -eq 0 ]; then
			set -e
			echo "- Installing SplameiPlay Update (Linux)"

			sudo cp "$SCRIPT_TMP_LOCATION" "$SCRIPT_FINAL_DEST"
			sudo chmod +x "$SCRIPT_FINAL_DEST"

			echo "- Cleaning up"

			rm "$SCRIPT_TMP_LOCATION"
			rm "$SCRIPT_TMP_SIG_LOCATION"
			rm "$TMP_SIG_LOCATION"

			if which splameiplay-update >/dev/null 2>&1; then
				echo
				echo "Done! SplameiPlay Update (Linux) is now installed!"
				echo "We'll now try to install the latest version of SplameiPlay for you now"
				echo "If it doesn't install, run this command below or contact us for support"
				echo
				echo "--------------------------"
				echo "    splameiplay-update"
				echo "--------------------------"
				echo
				echo
				echo

				splameiplay-update
			else
				echo
				echo "Done! SplameiPlay Update (Linux) is now installed!"
				echo "It doesn't seem like the command for SplameiPlay Update has assigned itself yet so please wait a bit then run the command below"
				echo "If the command doesn't work after a bit, please contact us for support"
				echo
				echo "--------------------------"
				echo "    splameiplay-update"
				echo "--------------------------"
			fi
		else
			set -e
			echo
			echo "ERR: Something went wrong when installing SplameiPlay. Please try again later or contact us for support"
			echo " - Failed to validate downloaded files"

			rm "$SCRIPT_TMP_SIG_LOCATION"
			rm "$TMP_SIG_LOCATION"
			rm "$SCRIPT_TMP_LOCATION"

			exit 1
		fi
	else
		echo "ERR: To install SplameiPlay, you need to install curl to your system so we can download the latest version and required files. Please install curl then try again"
		echo "For Debian/Ubuntu based systems, you can install curl via 'sudo apt install curl'"
		exit 1
	fi
}

main
