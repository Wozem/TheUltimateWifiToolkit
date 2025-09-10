#!/bin/bash

# Continuous download loop with ASCII banner and progress bar
# ⚠️ Use only on your own network!

URL="http://speedtest.tele2.net/1000GB.zip"

# Colors
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# Banner
echo -e "${GREEN}
@@@@@@@    @@@@@@    @@@@@@   @@@  @@@@@@@@  @@@ @@@
@@@@@@@@  @@@@@@@@  @@@@@@@   @@@  @@@@@@@@  @@@ @@@
@@!  @@@  @@!  @@@  !@@       @@!  @@!       @@! !@@
!@!  @!@  !@!  @!@  !@!       !@!  !@!       !@! @!!
@!@  !@!  @!@  !@!  !!@@!!    !!@  @!!!:!     !@!@!
!@!  !!!  !@!  !!!   !!@!!!   !!!  !!!!!:      @!!!
!!:  !!!  !!:  !!!       !:!  !!:  !!:         !!:
:!:  !:!  :!:  !:!      !:!   :!:  :!:         :!:
 :::: ::  ::::: ::  :::: ::    ::   ::          ::
:: :  :    : :  :   :: : :    :     :           :
${RESET}"

# Ctrl+C handler
trap ctrl_c INT
ctrl_c() {
    echo -e "\n${RED}[!] Ctrl+C detected. Exiting...${RESET}"
    pkill curl
    exit 0
}

echo -e "${CYAN}[+] Starting continuous download loop from: $URL${RESET}"

COUNT=1
while true; do
    echo -e "${YELLOW}[i] Download #$COUNT ...${RESET}"
    # -# = progress bar, -o /dev/null discards file
    curl -# -o /dev/null "$URL"
    COUNT=$((COUNT + 1))
done
