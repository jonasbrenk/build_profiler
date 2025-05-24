#!/bin/bash

# build_profiler.sh
# A script to profile build times by tracking file modifications.
# This version supports:
#   - Profiling the current directory (default)
#   - Profiling a specified directory
#   - Optionally executing a build command between scans using -b
#   - Provides a help output for invalid or explicit help requests.
#   - Features concise console output and prints results to console at the end.

# --- Configuration ---
# Temporary files to store file lists before and after the build
INITIAL_FILE_LIST=$(mktemp /tmp/build_profiler_initial_XXXXXX.txt)
FINAL_FILE_LIST=$(mktemp /tmp/build_profiler_final_XXXXXX.txt)
# Output CSV file name
OUTPUT_CSV="build_profile.csv"

# --- Functions ---

# Function to clean up temporary files on exit
cleanup() {
    echo "Cleaning up temp files..."
    rm -f "$INITIAL_FILE_LIST" "$FINAL_FILE_LIST"
    echo "Cleanup complete."
}

# Register the cleanup function to run on script exit or interruption
trap cleanup EXIT

# Function to display help output
display_help() {
    echo "Usage: $0 [directory_to_profile] [-b <build command>]"
    echo ""
    echo "Profiles a build process by tracking file modifications before and after a build."
    echo "Outputs a CSV file ('$OUTPUT_CSV') with modified or newly created files and their timestamps."
    echo ""
    echo "Arguments:"
    echo "  [directory_to_profile]  Optional. The path to the directory to profile."
    echo "                          If omitted, the current working directory will be used."
    echo "  -b <build command>      Optional. Executes the specified build command between the scans."
    echo "                          If omitted, the script will pause and prompt the user to run their build."
    echo "                          The build command should be quoted if it contains spaces (e.g., \"make clean all\")."
    echo ""
    echo "Examples:"
    echo "  $0                                   # Profiles the current directory, waits for manual build."
    echo "  $0 ./my_project_build_dir            # Profiles './my_project_build_dir', waits for manual build."
    echo "  $0 -b \"make clean all\"               # Profiles current dir, runs 'make clean all'."
    echo "  $0 /home/user/code/build -b \"ninja\"  # Profiles '/home/user/code/build', runs 'ninja'."
    echo "  $0 -h | $0 --help | $0 help          # Displays this help message."
    echo ""
}

# Function to scan the directory and record file modification times
# Arguments:
#   $1: Directory to scan
#   $2: Output file for the list (e.g., INITIAL_FILE_LIST or FINAL_FILE_LIST)
scan_directory() {
    local target_dir="$1"
    local output_file="$2"

    echo "Scanning '$target_dir'..."
    find "$target_dir" -type f -print0 | while IFS= read -r -d $'\0' file; do
        if stat -c "%Y %n" "$file" &>/dev/null; then
            stat -c "%Y %n" "$file"
        else
            echo "Warning: Could not stat file: $file (possibly deleted or permission issue)" >&2
        fi
    done | sort > "$output_file"

    if [ $? -ne 0 ]; then
        echo "Error: Failed to scan directory '$target_dir'." >&2
        exit 1
    fi
    echo "Scan complete."
}

# --- Main Script Logic ---

# Initialize variables
TARGET_DIR=$(pwd) # Default to current directory
BUILD_COMMAND=""
POS_ARGS=() # To store positional arguments (directory)

# Parse arguments
while (( "$#" )); do
    case "$1" in
        -h|--help|help)
            display_help
            exit 0
            ;;
        -b)
            shift # Remove -b
            if [[ -z "$1" ]]; then # Check if there's anything after -b
                echo "Error: The -b option requires a build command." >&2
                display_help
                exit 1
            fi
            BUILD_COMMAND="$@" # Capture the rest of the arguments as the build command
            break # No more arguments to parse after -b
            ;;
        *)
            # Collect positional arguments (expecting only one for directory)
            POS_ARGS+=("$1")
            shift # Consume the current argument
            ;;
    esac
done

# Check number of positional arguments (for the directory)
if [[ "${#POS_ARGS[@]}" -gt 1 ]]; then
    echo "Error: Only one target directory can be specified." >&2
    display_help
    exit 1
elif [[ "${#POS_ARGS[@]}" -eq 1 ]]; then
    TARGET_DIR="${POS_ARGS[0]}"
fi

# Resolve target directory to its absolute path for consistent paths in output
TARGET_DIR=$(realpath "$TARGET_DIR")
if [ $? -ne 0 ]; then
    echo "Error: Could not resolve absolute path for '$TARGET_DIR'." >&2
    exit 1
fi

# Validate that the determined TARGET_DIR exists and is a directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist or is not a directory." >&2
    exit 1
fi


echo "--- Build Profiler ---"
echo "Target: $TARGET_DIR"
echo "Output: $OUTPUT_CSV"
echo ""

# 1. Initial Scan
echo "STEP 1/3: Initial scan..."
scan_directory "$TARGET_DIR" "$INITIAL_FILE_LIST"
echo ""

# 2. Build Command Execution or User Prompt
if [[ -n "$BUILD_COMMAND" ]]; then
    echo "STEP 2/3: Running build command: $BUILD_COMMAND"
    # Execute the build command in a subshell, changing to TARGET_DIR first.
    (cd "$TARGET_DIR" && eval "$BUILD_COMMAND")
    BUILD_EXIT_CODE=$?
    if [ "$BUILD_EXIT_CODE" -ne 0 ]; then
        echo "WARNING: Build command exited with status $BUILD_EXIT_CODE." >&2
        echo "Profiling continues, but results might reflect an incomplete build." >&2
    else
        echo "Build completed."
    fi
else
    echo "STEP 2/3: Run your build process now."
    read -r -p "Press Enter to continue after build..."
fi
echo ""

# 3. Final Scan
echo "STEP 3/3: Final scan..."
scan_directory "$TARGET_DIR" "$FINAL_FILE_LIST"
echo ""

# 4. Comparison and CSV Generation
echo "Comparing files and generating CSV..."

# Read initial file states into an associative array (bash 4+ for efficiency)
declare -A initial_states
while IFS= read -r line; do
    timestamp=$(echo "$line" | awk '{print $1}')
    filepath=$(echo "$line" | awk '{$1=""; print $0}' | xargs)
    initial_states["$filepath"]="$timestamp"
done < "$INITIAL_FILE_LIST"

# Write CSV Header
echo "filepath,last_modification_timestamp" > "$OUTPUT_CSV"

# Iterate through final file states and compare
while IFS= read -r line; do
    final_epoch_timestamp=$(echo "$line" | awk '{print $1}')
    filepath=$(echo "$line" | awk '{$1=""; print $0}' | xargs)

    initial_epoch_timestamp="${initial_states[$filepath]}"

    # Check if the file is new OR if its timestamp has changed
    if [ -z "$initial_epoch_timestamp" ] || [ "$initial_epoch_timestamp" -ne "$final_epoch_timestamp" ]; then
        # Convert epoch timestamp to human-readable format
        human_readable_timestamp=$(date -d "@$final_epoch_timestamp" "+%Y-%m-%d %H:%M:%S %Z")

        # Output to CSV, ensuring fields are quoted to handle spaces/commas in paths/times
        echo "\"$filepath\",\"$human_readable_timestamp\"" >> "$OUTPUT_CSV"
    fi
done < "$FINAL_FILE_LIST"

if [ $? -ne 0 ]; then
    echo "Error: Failed to compare file lists or generate CSV." >&2
    exit 1
fi

echo "Build profiling complete. Results saved to '$OUTPUT_CSV'."

# 5. Print Results to Console
echo ""
echo "--- Build Profile Results ---"
if [ -s "$OUTPUT_CSV" ]; then # Check if file exists and is not empty
    if command -v column >/dev/null 2>&1; then
        # Use column -t for pretty printing if available
        cat "$OUTPUT_CSV" | column -t -s ','
    else
        # Fallback if 'column' is not available
        echo "Note: 'column' command not found, printing raw CSV."
        cat "$OUTPUT_CSV"
    fi
else
    echo "No changes detected or output file is empty." # This is the message you were looking for!
fi
echo "---------------------------"

# Cleanup is handled by the trap command on script exit.