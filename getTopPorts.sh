#!/bin/bash

script_name=$(basename "$0")

red='\033[0;31m'
yellow='\033[1;33m'
cyan='\033[0;36m'
nc='\033[0m'

protocol=""
num_ports=""
format=""

show_usage() {
    echo -e "${red}Usage: ${nc}$script_name --protocol <protocol> --number-of-ports <number> --format <format>"
    echo -e "${cyan}Available protocols: ${yellow}TCP, UDP, SCTP"
    echo -e "${cyan}Available formats: ${yellow}one-per-line, inline"
    echo -e "${cyan}Example: ${nc}$script_name --protocol TCP --number-of-ports 1000 --format one-per-line"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --protocol)
            protocol="$2"
            shift 2
            ;;
        --number-of-ports)
            num_ports="$2"
            shift 2
            ;;
        --format)
            format="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo -e "${red}Unknown option: ${yellow}$1${nc}"
            show_usage
            ;;
    esac
done

if [ -z "$protocol" ] || [ -z "$num_ports" ] || [ -z "$format" ]; then
    echo -e "${red}Error: All arguments are required${nc}"
    show_usage
fi

case "$protocol" in
    TCP|UDP|SCTP)
        ;;
    *)
        echo -e "${red}Error: Invalid protocol '${yellow}$protocol${red}'${nc}"
        echo -e "${cyan}Available protocols: ${yellow}TCP, UDP, SCTP${nc}"
        exit 1
        ;;
esac

case "$format" in
    one-per-line|inline)
        ;;
    *)
        echo -e "${red}Error: Invalid format '${yellow}$format${red}'${nc}"
        echo -e "${cyan}Available formats: ${yellow}one-per-line, inline${nc}"
        exit 1
        ;;
esac

if ! [[ "$num_ports" =~ ^[1-9][0-9]*$ ]]; then
    echo -e "${red}Error: Number of ports must be a positive integer${nc}"
    exit 1
fi

if [ "$num_ports" -gt 65535 ]; then
    echo -e "${red}Error: Number of ports cannot be greater than 65535${nc}"
    exit 1
fi

NMAP_SERVICES="/usr/share/nmap/nmap-services"

if [ ! -f "$NMAP_SERVICES" ]; then
    echo -e "${red}Error: Cannot find ${yellow}$NMAP_SERVICES${nc}"
    echo -e "${cyan}Make sure nmap is installed${nc}"
    exit 1
fi

protocol_LOWER=$(echo "$protocol" | tr '[:upper:]' '[:lower:]')

if [ ! -d "$format" ]; then
    mkdir -p "$format"
    echo -e "${cyan}Created directory: ${yellow}$format/${nc}"
fi

OUTPUT_FILE="$format/top-${num_ports}-${protocol_LOWER}-ports.txt"

echo -e "${cyan}Getting ${yellow}$num_ports ${cyan}most common ${yellow}$protocol ${cyan}ports in ${yellow}$format ${cyan}format...${nc}"

case "$format" in
    one-per-line)
        awk '!/^#/ && $2 ~ /^[0-9]+\/'"$protocol_LOWER"'/ && $3 ~ /^[0-9.]+$/ {
          split($2,p,"/"); print p[1]","$3
        }' "$NMAP_SERVICES" \
          | sort -t, -k2 -nr \
          | awk -F, '!seen[$1]++ { print $1 }' \
          | head -n "$num_ports" > "$OUTPUT_FILE"
        ;;
    inline)
        awk '!/^#/ && $2 ~ /^[0-9]+\/'"$protocol_LOWER"'/ && $3 ~ /^[0-9.]+$/ {
          split($2,p,"/"); print p[1]","$3
        }' "$NMAP_SERVICES" \
          | sort -t, -k2 -nr \
          | awk -F, '!seen[$1]++ { print $1 }' \
          | head -n "$num_ports" \
          | tr '\n' ',' \
          | sed 's/,$//' > "$OUTPUT_FILE"
        ;;
esac

if [ "$format" = "inline" ]; then
    ACTUAL_PORTS=$(tr ',' '\n' < "$OUTPUT_FILE" | wc -l)
else
    ACTUAL_PORTS=$(wc -l < "$OUTPUT_FILE")
fi

echo -e "${cyan}Process completed ${yellow}✓${nc}"
echo -e "${cyan}Number of ports obtained: ${yellow}$ACTUAL_PORTS${nc}"
echo -e "${cyan}$protocol ports saved in: ${yellow}$OUTPUT_FILE${nc}"
echo -e "${cyan}Format: ${yellow}$format${nc}"

xclip -selection clipboard < "$OUTPUT_FILE"
echo -e "${cyan}Content copied to clipboard ${yellow}✓${nc}"
