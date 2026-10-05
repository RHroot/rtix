#!/usr/bin/env bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Header
echo -e "${BLUE}"
echo "   __  ___   __  __  _____  _  ________  ___  "
echo "  /  |/  /  / / / / / ___/ / |/ / __/ / / _ \\ "
echo " / /|_/ /  / /_/ / / /__ /    / _// /_/ // / "
echo "/_/  /_/   \____/  \___//_/|_/___/____/____/  "
echo -e "${NC}"
echo "---------------------------------------------"

# Prompt for SSID with validation
while true; do
  read -p "$(echo -e "${YELLOW}🌐 Enter Wi-Fi SSID: ${NC}")" SSID
  if [[ -z "$SSID" ]]; then
    echo -e "${RED}❌ Error: SSID cannot be empty.${NC}"
  else
    break
  fi
done

# Prompt for password (hidden input) with validation
while true; do
  read -s -p "$(echo -e "${YELLOW}🔑 Enter password (hidden): ${NC}")" PASSWORD
  echo
  if [[ -z "$PASSWORD" ]]; then
    echo -e "${RED}❌ Error: Password cannot be empty.${NC}"
  else
    break
  fi
done

# Action indicator
echo -e "\n${BLUE}🔄 Attempting to connect to ${GREEN}$SSID${BLUE}...${NC}"

# Modify connection
if nmcli connection modify "$SSID" wifi-sec.psk "$PASSWORD" 2>/dev/null; then
  echo -e "${GREEN}✓ Updated credentials for ${SSID}${NC}"
else
  echo -e "${YELLOW}⚠ No existing profile found. Creating new connection...${NC}"
  nmcli device wifi connect "$SSID" password "$PASSWORD" && exit 0
fi

# Connect
if nmcli connection up "$SSID" >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Successfully connected to ${SSID}!${NC}"
  # Show IP
  IP=$(ip -4 addr show wlp0s20f3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
  echo -e "${BLUE}📶 Your IP: ${GREEN}$IP${NC}"
else
  echo -e "${RED}❌ Failed to connect to ${SSID}.${NC}"
  echo -e "${YELLOW}Possible reasons:"
  echo "- Incorrect password"
  echo "- Weak signal"
  echo "- NetworkManager issues"
  echo -e "Run ${BLUE}journalctl -u NetworkManager${YELLOW} for details.${NC}"
fi
