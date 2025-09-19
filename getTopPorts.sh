#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
PROTOCOL=""
NUM_PORTS=""
FORMAT=""

# Function to show usage
show_usage() {
    echo -e "${RED}Usage: ${NC}$0 --protocol <protocol> --number-of-ports <number> --format <format>"
    echo -e "${CYAN}Available protocols: ${YELLOW}TCP, UDP, SCTP"
    echo -e "${CYAN}Available formats: ${YELLOW}one-per-line, inline"
    echo -e "${CYAN}Example: ${NC}$0 --protocol TCP --number-of-ports 1000 --format one-per-line"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        --number-of-ports)
            NUM_PORTS="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown option: ${YELLOW}$1${NC}"
            show_usage
            ;;
    esac
done

# Validate that all required arguments are provided
if [ -z "$PROTOCOL" ] || [ -z "$NUM_PORTS" ] || [ -z "$FORMAT" ]; then
    echo -e "${RED}Error: All arguments are required${NC}"
    show_usage
fi

# Validate protocol
case "$PROTOCOL" in
    TCP|UDP|SCTP)
        # Valid protocol
        ;;
    *)
        echo -e "${RED}Error: Invalid protocol '${YELLOW}$PROTOCOL${RED}'${NC}"
        echo -e "${CYAN}Available protocols: ${YELLOW}TCP, UDP, SCTP${NC}"
        exit 1
        ;;
esac

# Validate format
case "$FORMAT" in
    one-per-line|inline)
        # Valid format
        ;;
    *)
        echo -e "${RED}Error: Invalid format '${YELLOW}$FORMAT${RED}'${NC}"
        echo -e "${CYAN}Available formats: ${YELLOW}one-per-line, inline${NC}"
        exit 1
        ;;
esac

# Validate that number of ports is a positive number and not greater than 65535
if ! [[ "$NUM_PORTS" =~ ^[1-9][0-9]*$ ]]; then
    echo -e "${RED}Error: Number of ports must be a positive integer${NC}"
    exit 1
fi

if [ "$NUM_PORTS" -gt 65535 ]; then
    echo -e "${RED}Error: Number of ports cannot be greater than 65535${NC}"
    exit 1
fi

NMAP_SERVICES="/usr/share/nmap/nmap-services"

# Check if nmap-services file exists
if [ ! -f "$NMAP_SERVICES" ]; then
    echo -e "${RED}Error: Cannot find ${YELLOW}$NMAP_SERVICES${NC}"
    echo -e "${CYAN}Make sure nmap is installed${NC}"
    exit 1
fi

# Convert protocol to lowercase for filename but keep original for display
PROTOCOL_LOWER=$(echo "$PROTOCOL" | tr '[:upper:]' '[:lower:]')

# Create directory for the format if it doesn't exist
if [ ! -d "$FORMAT" ]; then
    mkdir -p "$FORMAT"
    echo -e "${CYAN}Created directory: ${YELLOW}$FORMAT/${NC}"
fi

# Output filename inside the format directory
OUTPUT_FILE="$FORMAT/top-${NUM_PORTS}-${PROTOCOL_LOWER}-ports.txt"

echo -e "${CYAN}Getting ${YELLOW}$NUM_PORTS ${CYAN}most common ${YELLOW}$PROTOCOL ${CYAN}ports in ${YELLOW}$FORMAT ${CYAN}format...${NC}"

# Get the ports and format them according to the selected format
case "$FORMAT" in
    one-per-line)
        # One port per line
        awk '!/^#/ && $2 ~ /^[0-9]+\/'"$PROTOCOL_LOWER"'/ && $3 ~ /^[0-9.]+$/ {
          split($2,p,"/"); print p[1]","$3
        }' "$NMAP_SERVICES" \
          | sort -t, -k2 -nr \
          | awk -F, '!seen[$1]++ { print $1 }' \
          | head -n "$NUM_PORTS" > "$OUTPUT_FILE"
        ;;
    inline)
        # Inline: 3,80,90,32
        awk '!/^#/ && $2 ~ /^[0-9]+\/'"$PROTOCOL_LOWER"'/ && $3 ~ /^[0-9.]+$/ {
          split($2,p,"/"); print p[1]","$3
        }' "$NMAP_SERVICES" \
          | sort -t, -k2 -nr \
          | awk -F, '!seen[$1]++ { print $1 }' \
          | head -n "$NUM_PORTS" \
          | tr '\n' ',' \
          | sed 's/,$//' > "$OUTPUT_FILE"
        ;;
esac

# Get the actual number of ports obtained
if [ "$FORMAT" = "inline" ]; then
    ACTUAL_PORTS=$(tr ',' '\n' < "$OUTPUT_FILE" | wc -l)
else
    ACTUAL_PORTS=$(wc -l < "$OUTPUT_FILE")
fi

echo -e "${CYAN}Process completed ${YELLOW}✓${NC}"
echo -e "${CYAN}Number of ports obtained: ${YELLOW}$ACTUAL_PORTS${NC}"
echo -e "${CYAN}$PROTOCOL ports saved in: ${YELLOW}$OUTPUT_FILE${NC}"
echo -e "${CYAN}Format: ${YELLOW}$FORMAT${NC}"

# Copy content to clipboard using xclip
xclip -selection clipboard < "$OUTPUT_FILE"
echo -e "${CYAN}Content copied to clipboard ${YELLOW}✓${NC}"
