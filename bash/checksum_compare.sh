#!/bin/bash

# Enable strict mode and better buffering
set -u
set -o pipefail

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <path1> <path2> [logfile] [error_logfile]"
    exit 1
fi

PATH1=$1
PATH2=$2
LOGFILE=${3:-"checksums_compare.log"}
ERROR_LOGFILE=${4:-"checksums_compare-error.log"}
PROCESS_NAME="checksum_comparison"

# Create temporary files for checksums
TEMP_CHECKSUM1=$(mktemp)
TEMP_CHECKSUM2=$(mktemp)

# Function to calculate MD5 checksum for a single file
calculate_file_checksum() {
    local file=$1
    local checksum_file=$2

    if [ -f "$file" ]; then
        checksum=$(md5sum "$file" | awk '{ print $1 }')
        echo "Processing $file: $checksum"
        echo "$checksum" > "$checksum_file"
    else
        log_error "File $file does not exist"
        exit 1
    fi
}

# Function to calculate MD5 checksums for all files in a given path
calculate_checksums() {
    local path=$1
    local checksum_file=$2

    # Clear the checksum file
    > "$checksum_file"

    # Recursively calculate MD5 checksums for all files in the path and its subdirectories
    find "$path" -type f | while read -r file; do
        if [ -f "$file" ]; then
            relative_path="${file#$path/}"
            checksum=$(md5sum "$file" | awk '{ print $1 }')
            echo "Processing $file: $checksum"
            echo "$relative_path $checksum $file" >> "$checksum_file"
        fi
    done
    sort -k 1 -o "$checksum_file" "$checksum_file"
}

# Function to log messages in syslog format
log_message() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "%s %s: %s\n" "$timestamp" "$PROCESS_NAME" "$message" >> "$LOGFILE"
}

# Function to log error messages in syslog format
log_error() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "%s %s: %s\n" "$timestamp" "$PROCESS_NAME" "$message" >> "$ERROR_LOGFILE"
}

# Function to escape special characters in a string for grep
escape_for_grep() {
    echo "$1" | sed 's/[]\/$*.^|[]/\\&/g'
}

# Check if paths are files or directories
if [ -f "$PATH1" ] && [ -f "$PATH2" ]; then
    # Both paths are files, compare them directly
    calculate_file_checksum "$PATH1" "$TEMP_CHECKSUM1"
    calculate_file_checksum "$PATH2" "$TEMP_CHECKSUM2"

    # Read the checksums
    checksum1=$(cat "$TEMP_CHECKSUM1")
    checksum2=$(cat "$TEMP_CHECKSUM2")

    if [ "$checksum1" = "$checksum2" ]; then
        log_message "[OK] Checksums match for $PATH1 and $PATH2: $checksum1"
    else
        log_message "[MISMATCH] Checksums do not match for $PATH1 and $PATH2: $checksum1 vs $checksum2"
        log_error "[MISMATCH] Checksums do not match for $PATH1 and $PATH2: $checksum1 vs $checksum2"
        mismatch=1
    fi
else
    # At least one path is a directory, use directory comparison
    if [ ! -d "$PATH1" ] || [ ! -d "$PATH2" ]; then
        log_error "Both paths must be either files or directories"
        exit 1
    fi

    # Calculate checksums for both paths
    calculate_checksums "$PATH1" "$TEMP_CHECKSUM1"
    calculate_checksums "$PATH2" "$TEMP_CHECKSUM2"

    # Compare the checksums file by file
    mismatch=0
    while IFS= read -r line1; do
        relative_path=$(echo "$line1" | awk '{print $1}')
        checksum1=$(echo "$line1" | awk '{print $2}')
        original_path1=$(echo "$line1" | cut -d' ' -f3-)

        # Find the corresponding line in the second checksum file
        escaped_path=$(escape_for_grep "$relative_path")
        line2=$(grep "^$escaped_path " "$TEMP_CHECKSUM2")

        if [ -n "$line2" ]; then
            checksum2=$(echo "$line2" | awk '{print $2}')
            original_path2=$(echo "$line2" | cut -d' ' -f3-)
            if [ "$checksum1" != "$checksum2" ]; then
                log_message "[MISMATCH] Checksums do not match for $original_path1 and $original_path2: $checksum1 vs $checksum2"
                log_error "[MISMATCH] Checksums do not match for $original_path1 and $original_path2: $checksum1 vs $checksum2"
                mismatch=1
            else
                log_message "[OK] Checksums match for $original_path1: $checksum1"
            fi
            # Remove the processed line from the second checksum file
            escaped_path=$(escape_for_grep "$relative_path")
            grep -v "^$escaped_path " "$TEMP_CHECKSUM2" > "${TEMP_CHECKSUM2}.tmp"
            mv "${TEMP_CHECKSUM2}.tmp" "$TEMP_CHECKSUM2"
        else
            log_message "[MISSING] File $original_path1 is missing in $PATH2"
            log_error "[MISSING] File $original_path1 is missing in $PATH2"
            mismatch=1
        fi
    done < "$TEMP_CHECKSUM1"

    # Check for any remaining lines in the second checksum file
    while IFS= read -r line2; do
        original_path2=$(echo "$line2" | cut -d' ' -f3-)
        log_message "[MISSING] File $original_path2 is missing in $PATH1"
        log_error "[MISSING] File $original_path2 is missing in $PATH1"
        mismatch=1
    done < "$TEMP_CHECKSUM2"

    if [ $mismatch -eq 0 ]; then
        log_message "All checksums match."
    fi
fi

echo "Checksums written to $LOGFILE"
echo "Errors and mismatches written to $ERROR_LOGFILE"

# Clean up temporary files
rm -f "$TEMP_CHECKSUM1" "$TEMP_CHECKSUM2"
