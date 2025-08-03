#!/bin/bash

# Mosquitto Password Hash Generator
# This script helps generate password hashes for use in values.yaml

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <username> <password>

Generate a Mosquitto password hash for use in Helm values.

OPTIONS:
    -h, --help          Show this help message
    -c, --copy          Copy hash to clipboard (requires pbcopy/xclip)
    -f, --format        Output in values.yaml format

EXAMPLES:
    $0 admin mypassword123
    $0 --format admin mypassword123
    $0 --copy admin mypassword123

OUTPUT:
    The script outputs a password hash that can be used in values.yaml:

    auth:
      users:
        - username: admin
          passwordHash: "\$6\$salt\$hash..."

REQUIREMENTS:
    - Docker (to run mosquitto_passwd)
    OR
    - mosquitto-clients package installed locally

EOF
}

# Parse command line arguments
COPY_TO_CLIPBOARD=false
FORMAT_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -c|--copy)
            COPY_TO_CLIPBOARD=true
            shift
            ;;
        -f|--format)
            FORMAT_OUTPUT=true
            shift
            ;;
        -*)
            echo "Unknown option $1"
            print_usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -ne 2 ]]; then
    echo "Error: Username and password are required"
    print_usage
    exit 1
fi

USERNAME="$1"
PASSWORD="$2"

# Function to generate hash using mosquitto_passwd
generate_hash() {
    local username="$1"
    local password="$2"
    local temp_file=$(mktemp)

    # Try to use local mosquitto_passwd first
    if command -v mosquitto_passwd >/dev/null 2>&1; then
        echo "Using local mosquitto_passwd..."
        mosquitto_passwd -b "$temp_file" "$username" "$password" 2>/dev/null
        cat "$temp_file" | cut -d: -f2
    # Fall back to Docker
    elif command -v docker >/dev/null 2>&1; then
        echo "Using Docker mosquitto_passwd..." >&2
        docker run --rm -v "$temp_file:/tmp/passwd" eclipse-mosquitto:latest \
            mosquitto_passwd -b /tmp/passwd "$username" "$password" >/dev/null 2>&1
        docker run --rm -v "$temp_file:/tmp/passwd" eclipse-mosquitto:latest \
            cat /tmp/passwd | cut -d: -f2
    else
        echo "Error: Neither mosquitto_passwd nor Docker is available" >&2
        echo "Please install mosquitto-clients or Docker" >&2
        exit 1
    fi

    rm -f "$temp_file"
}

# Generate the password hash
echo "Generating password hash for user '$USERNAME'..." >&2
HASH=$(generate_hash "$USERNAME" "$PASSWORD")

# Escape the hash for YAML (escape $ characters)
ESCAPED_HASH=$(echo "$HASH" | sed 's/\$/\\$/g')

# Output based on format preference
if [[ "$FORMAT_OUTPUT" == "true" ]]; then
    OUTPUT="    - username: $USERNAME
      passwordHash: \"$ESCAPED_HASH\""
else
    OUTPUT="$ESCAPED_HASH"
fi

echo "$OUTPUT"

# Copy to clipboard if requested
if [[ "$COPY_TO_CLIPBOARD" == "true" ]]; then
    if command -v pbcopy >/dev/null 2>&1; then
        echo "$OUTPUT" | pbcopy
        echo "Hash copied to clipboard!" >&2
    elif command -v xclip >/dev/null 2>&1; then
        echo "$OUTPUT" | xclip -selection clipboard
        echo "Hash copied to clipboard!" >&2
    else
        echo "Warning: Could not copy to clipboard (pbcopy/xclip not found)" >&2
    fi
fi
