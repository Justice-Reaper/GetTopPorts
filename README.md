# GetTopPorts
A Bash script that extracts the most common ports from Nmap, saves them to a text file in two different formats, and automatically copies the output to the clipboard

# Help panel

```
# ./getTopPorts.sh -h
Usage: ./getTopPorts.sh --protocol <protocol> --number-of-ports <number> --format <format>
Available protocols: TCP, UDP, SCTP
Available formats: one-per-line, inline
Example: ./getTopPorts.sh --protocol TCP --number-of-ports 1000 --format one-per-line
```

# Usage

```
# ./getTopPorts.sh --protocol TCP --number-of-ports 8000 --format one-per-line      
Getting 8000 most common TCP ports in one-per-line format...
Process completed ✓
Number of ports obtained: 8000
TCP ports saved in: top-8000-tcp-ports.txt
Format: one-per-line
Content copied to clipboard ✓
```
