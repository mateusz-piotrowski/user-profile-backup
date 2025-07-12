#!/usr/bin/env bash

#---
# SECTION: Script Metadata
#---
# Script Name: user-profile-backup.sh
# Description: A robust script to back up a user's home directory using rsync.
# Author: Mateusz Piotrowski <mateusz7piotrowski@gmail.com>
# Version: 1.3.0
# License: MIT (or choose a suitable license like GPL, Apache 2.0)
# Created Date: 2024-06-20
# Last Modified Date: 2025-07-13

#---
# SECTION: Configuration and Environment Setup
#---

# Exit immediately if a command exits with a non-zero status.
set -o errexit

# Treat unset variables and parameters as an error when performing parameter expansion.
set -o nounset

# The return value of a pipeline is the status of the last command to exit with a non-zero status.
set -o pipefail

# Define script-specific variables
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
readonly START_DATE=$(date "+%Y-%m-%d %H:%M:%S")
readonly LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME%.*}_$START_DATE.log"

# --- External Configuration Loading ---
readonly CONFIG_FILE="${SCRIPT_DIR}/user-profile-backup.conf"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "FATAL: Configuration file not found at: ${CONFIG_FILE}" >&2
    echo "Please ensure 'user-profile-backup.conf' exists in the same directory as the script." >&2
    exit 1
fi

# Source the configuration file to load variables like SOURCE_DIR, BACKUP_DIR, etc.
# shellcheck source=/dev/null
source "${CONFIG_FILE}"

# Default values for script options/flags
VERBOSE=0
DRY_RUN=0

#---
# SECTION: Helper Functions
#---

# log(): Function for consistent logging.
log() {
    local message="$1"
    local level="${2:-INFO}" # Default level is INFO
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

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
error_exit() {
    local message="$1"
    local exit_code="${2:-1}" # Default exit code is 1
    log "${message}" "ERROR"
    exit "${exit_code}"
}

# usage(): Displays the script's usage information and exits.
usage() {
    echo "Usage: ${SCRIPT_NAME} [OPTIONS]"
    echo "Performs a robust backup of the user's home directory."
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Enable verbose output from rsync."
    echo "  -d, --dry-run    Simulate backup without making actual changes."
    echo "  -h, --help       Display this help message and exit."
    echo ""
    echo "Examples:"
    echo "  ${SCRIPT_NAME} --verbose"
    echo "  ${SCRIPT_NAME} -d"
    echo ""
    exit 0
}

# parse_args(): Parses command-line arguments.
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -h|--help)
                usage
                ;;
            --)
                shift
                break
                ;;
            -*)
                error_exit "Unknown or invalid option: '$1'. Use -h for help."
                ;;
            *)
                error_exit "Unexpected argument: '$1'. This script does not accept positional arguments."
                ;;
        esac
    done
}

# validate_dependencies(): Checks for necessary commands and directories.
validate_dependencies() {
    log "Validating script dependencies..." "DEBUG"
    if ! command -v rsync &> /dev/null; then
        error_exit "Required command 'rsync' not found. Please install it."
    fi
    if [[ ! -d "${SOURCE_DIR}" ]]; then
        error_exit "Source directory not found: ${SOURCE_DIR}"
    fi

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log "Backup destination directory not found. Creating it: ${BACKUP_DIR}" "WARN"
        mkdir -p "${BACKUP_DIR}" || error_exit "Failed to create backup destination directory: ${BACKUP_DIR}"
    fi

    if [[ ! -f "${EXCLUDE_FILE}" ]]; then
        error_exit "Exclude file not found: ${EXCLUDE_FILE}"
    fi
    log "All required dependencies found." "DEBUG"
}

# main(): The main logic of the script.
main() {
    log "Script '${SCRIPT_NAME}' started."

    validate_dependencies

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "Dry run mode enabled. Simulating backup without making changes." "WARN"
    fi

    log "Starting backup from '${SOURCE_DIR}' to '${BACKUP_DIR}'."

    # Build the rsync command options in an array for robustness
    local rsync_opts=()
    rsync_opts+=(-bvh --delete --delete-excluded --recursive)
    rsync_opts+=("--exclude-from=${EXCLUDE_FILE}")

    if [[ "${VERBOSE}" -eq 1 ]]; then
        rsync_opts+=(-h --progress)
        log "Verbose mode enabled." "DEBUG"
    fi

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        rsync_opts+=(--dry-run)
    fi

    # Execute the backup
    rsync "${rsync_opts[@]}" "${SOURCE_DIR}/" "${BACKUP_DIR}/" >> "${LOG_FILE}" 2>&1

    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log "Dry run simulation finished successfully."
    else
        log "Backup completed successfully."
    fi

    log "Script '${SCRIPT_NAME}' finished."
}

#---
# SECTION: Main Execution Block
#---

# Ensure a log file exists or is created before any logging
touch "${LOG_FILE}" || error_exit "Failed to create log file: ${LOG_FILE}"

parse_args "$@"

main

exit 0
