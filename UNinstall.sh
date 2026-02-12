#!/usr/bin/env bash
set -euo pipefail       # exit immediately in case of error

# Uninstallation of the shrink_pdf command and the "Shrink PDF" Nemo action

# For translations of this installation script
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
export TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"

# Colors and highligh in outputs
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

ERR="${RED}${BOLD}"
OK="${GREEN}${BOLD}"
WARN="${YELLOW}${BOLD}"
HIGHLIGHT="${BOLD}"

# Always "press any key" prompt at the end
PRESS_ANY_KEY=true


# Display a given message then waits for any key to be pressed, then return
# $1: Optional message to display. Default: "Press any key...'"
function press_any_key () {
    echo
    if [ $# -ge 1 ]; then
        echo -n "${1}"
    else
        echo -n "$(eval_gettext "\${HIGHLIGHT}Press any key...\${RESET}")"
    fi
    read -s -n 1
    echo
}

# Exit this script with an exit code, possibly after a "press any key"
function exit_script () {
    local exit_message
    if [ $# -ge 2 ]; then
        exit_message="${2}"
    else
        exit_message="$(eval_gettext "\${HIGHLIGHT}Press any key to finish...\${RESET}")"
    fi
    if [ "${PRESS_ANY_KEY}" = true ]; then press_any_key "${exit_message}"; fi

    if [ $# -ge 1 ]; then
        exit ${1}
    else
        echo "$(eval_gettext "\${ERR}ERROR: function called with incorrect number of parameter.\${RESET}" )" 1>&2
        exit 255    # bug: function called with incorrect number of parameter
    fi
}


# User input y or : Continue? y or n: n ==> return 0 (success), y ==> return 1 (failure)
# $1 is the text prompt. (' [y/n]' is appended)
# return 0 if y/Y
# retrun 1 if n/N
function yes_or_no () {
    yn_p="${1}""$(gettext " [y/n]: ")"
    if [ $# -ge 1 ]; then
        yn_p="${1} ""$(gettext "[y/n]: ")"
    else
        yn_p="$(gettext "Yes or No? [y/n]: ")"
    fi
    while true; do
        read -n 1 -p "${yn_p}" yn
        echo
        case ${yn^^} in
            "$(gettext "Y")") return 0 ;;  
            "$(gettext "N")") return 1 ;;  
        esac
    done
}


# Unstallation of a file: rm <source_path> <dest_path>
# $1 Mandatory. Description of the file. Example "Main command", "French translation", etc.
# $2 Mandatory. Destination path.
function uninstall_file () {
    if [ $# -ne 2 ]; then
        echo "$(eval_gettext "\${ERR}ERROR: \${FUNCNAME} function called with incorrect number of parameter.\${RESET}" )" 1>&2
        exit_script 255    # bug: function called with incorrect parameter
    fi
    local file_description=$1
    local dest_path=$2

    echo -n "$( eval_gettext "UNinstallation of \"\${file_description}\": \"\${dest_path}\"... " )"
    if [ -f "${dest_path}" ]; then
        if ! sudo rm "${dest_path}" ; then
            echo "$(eval_gettext "\${ERR}ERROR: failed to uninstall the file.\${RESET}" )" 1>&2
            exit_script 2   # Installation failure
        fi
    else
        echo -n "$( gettext "Does not exist. " )"
    fi
    echo "$(gettext "ok.")"
}



# Source directory: where is this script currently running
SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Name of the script ot install
SCRIPT_FILENAME="shrink_pdf"

NEMO_ACTION_MENU="$(gettext "Shrink PDF")"

# Uninstall confirmation
echo
echo "$( eval_gettext "This will UNinstall \"\${SCRIPT_FILENAME}\"." )"
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Canceled, ok.")"
    exit_script 0
fi 

echo

# Ask for elevated privileges (sudo)
echo -n "$( gettext "You need elevated privileges to uninstall: " )"
sudo -v
if [ $? -ne 0 ]; then
    echo "$( gettext "\${ERR}ERROR: Uninstallation canceled: Failed to get elevated privileges (sudo).\${RESET}" )"
    exit_script 253       # Error: missing prerequisite
fi
echo "$( gettext "ok for elevated privileges (sudo).")"

echo

# Install the script for all users of the system, in /usr/bin (should be in $PATH)
file_description="main command"
dest_file_path="/usr/bin/${SCRIPT_FILENAME}"
uninstall_file "${file_description}" "${dest_file_path}"

# files and directory for translation files of the script
LOCALE_FILE_NAME="shrink_pdf.mo"
LOCALE_DIRECTORY="/usr/share/locale"

# Install the 'fr' translation files of the script for all users of the system, in /usr/share/locale
file_description="French translation"
lang="fr"
dest_file_path="${LOCALE_DIRECTORY}/${lang}/LC_MESSAGES/${LOCALE_FILE_NAME}"
uninstall_file "${file_description}" "${dest_file_path}"


# If Nemo is present, install the Nemo action for all users of the system
file_description="Nemo action"
nemo_action_filename="shrink_pdf.nemo_action"
dest_file_path="/usr/share/nemo/actions/${nemo_action_filename}"
uninstall_file "${file_description}" "${dest_file_path}"

# Install the English man page for all users of the system
file_description="English man page"
man_page_en_filename="${SCRIPT_FILENAME}.1.gz"
dest_file_path="/usr/share/man/man1/${man_page_en_filename}"
uninstall_file "${file_description}" "${dest_file_path}"


# Install the French man page for all users of the system
file_description="French man page"
lang="fr"
dest_file_path="/usr/share/man/${lang}/man1/${SCRIPT_FILENAME}.1.gz"
uninstall_file "${file_description}" "${dest_file_path}"


# The End
echo
echo "$(gettext "The UNinstallation succeeded.")"

press_any_key
exit 0

