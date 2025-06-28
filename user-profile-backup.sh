#!/usr/bin/env bash

#---
# SECTION: Script Metadata
#---
# Script Name: user-profile-backup.sh
# Description: Briefly describe the purpose of this script.
# Author: Your Name <your.email@example.com>
# Version: 1.0.0
# License: MIT (or choose a suitable license like GPL, Apache 2.0)
# Created Date: 2024-06-20
# Last Modified Date: 2024-06-20

#---
# SECTION: Configuration and Environment Setup
#---

# Exit immediately if a command exits with a non-zero status.
# This prevents subsequent commands from running if an earlier one failed.
set -o errexit

# Treat unset variables and parameters as an error when performing parameter expansion.
# This helps catch typos and ensures variables are intentionally defined.
set -o nounset

# The return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully. Essential for robust error checking in pipelines.
set -o pipefail

# Optional: Enable a debug mode where all executed commands are printed to stderr.
# Uncomment for debugging.
# set -o xtrace

# Optional: Internal Field Separator. Commonly set to newline to prevent word splitting issues
# with filenames containing spaces, but use with caution as it affects all word splitting.
# IFS=$'\n\t'

# Define script-specific variables
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME%.*}.log" # Log file name based on script name

# Default values for script options/flags
VERBOSE=0
DRY_RUN=0
# Add your custom default variables here, e.g.:
# CONFIG_ENABLED=0

#---
# SECTION: Helper Functions
#---

# log(): Function for consistent logging. Messages are printed to stderr for immediate display
# and appended to a log file for persistent records.
# Usage: log "Your message here" [LEVEL]
# Levels: INFO (default), WARN, ERROR, DEBUG
log() {
    local message="$1"
    local level="${2:-INFO}" # Default level is INFO
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Determine color based on log level (for terminal output only)
    local color_code="\033[0m" # Reset
    case "${level}" in
        INFO)  color_code="\033[0;32m";; # Green
        WARN)  color_code="\033[0;33m";; # Yellow
        ERROR) color_code="\033[0;31m";; # Red
        DEBUG) color_code="\033[0;36m";; # Cyan
    esac

    # Print to stderr for immediate terminal display (with color codes)
    echo -e "${color_code}${timestamp} [${level}] ${message}\033[0m" >&2

    # Append to log file (without color codes)
    echo "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
}

# error_exit(): Logs an error message and exits the script with a failure status.
# Usage: error_exit "Reason for failure." [EXIT_CODE]
error_exit() {
    local message="$1"
    local exit_code="${2:-1}" # Default exit code is 1
    log "${message}" "ERROR"
    exit "${exit_code}"
}

# usage(): Displays the script's usage information and exits.
# Usage: usage
usage() {
    echo "Usage: ${SCRIPT_NAME} [OPTIONS]"
    echo "A boilerplate script demonstrating best practices."
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Enable verbose output (shows DEBUG messages)."
    echo "  -d, --dry-run    Simulate actions without making actual changes."
    echo "  -h, --help       Display this help message and exit."
    # Add your custom options here, e.g.:
    # echo "  -c, --config     Enable a specific configuration mode."
    echo ""
    echo "Examples:"
    echo "  ${SCRIPT_NAME} --verbose"
    echo "  ${SCRIPT_NAME} -d"
    echo ""
    exit 0
}

# parse_args(): Parses command-line arguments and sets script variables accordingly.
# Only handles options/flags.
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=1
                log "Verbose mode enabled." "DEBUG"
                shift # Consume the argument
                ;;
            -d|--dry-run)
                DRY_RUN=1
                log "Dry run mode enabled. No actual changes will be made." "WARN"
                shift
                ;;
            -h|--help)
                usage # Calls the usage function and exits
                ;;
            # Add your custom option parsing here, e.g.:
            # -c|--config)
            #     CONFIG_ENABLED=1
            #     log "Configuration mode enabled." "DEBUG"
            #     shift
            #     ;;
            --) # End of all options
                shift
                break # Stop processing options, remaining are positional arguments (which we don't expect)
                ;;
            -*)
                error_exit "Unknown or invalid option: '$1'. Use -h for help."
                ;;
            *) # Any remaining argument is unexpected if no positional arguments are needed
                error_exit "Unexpected argument: '$1'. This script does not accept positional arguments. Use -h for help."
                ;;
        esac
    done

    log "Arguments parsed successfully." "DEBUG"
}

# validate_dependencies(): Checks for necessary commands/executables.
validate_dependencies() {
    log "Validating script dependencies..." "DEBUG"
    # Example: Check for `curl`
    if ! command -v curl &> /dev/null; then
        error_exit "Required command 'curl' not found. Please install it."
    fi
    # Add more dependency checks here as needed
    log "All required dependencies found." "DEBUG"
}

# main(): The main logic of the script.
main() {
    log "Script '${SCRIPT_NAME}' started."

    # Perform dependency validation
    validate_dependencies

    # Example of conditional logic based on parsed options/flags
    if [[ "${VERBOSE}" -eq 1 ]]; then
        log "Verbose output is active for main logic." "INFO"
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "This is a dry run. No actual changes will be made." "WARN"
        log "Simulating primary operation..."
        # Add dry-run specific logic here
    else
        log "Executing actual script operations."
        # Place your core script logic here.
        # This is where the main work of your script happens.
        echo "Performing the main task of the script..."
        # Example:
        # Some_command --option value
        # Another_command "some_input"
    fi

    log "Script '${SCRIPT_NAME}' finished successfully."
}

#---
# SECTION: Main Execution Block
#---

# Ensure a log file exists or is created before any logging
touch "${LOG_FILE}" || error_exit "Failed to create log file: ${LOG_FILE}"

# Capture all arguments passed to the script (which should only be options here)
parse_args "$@"

# Call the main function to start the script's primary logic
main

# Exit with success status
exit 0
