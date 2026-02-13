#!/usr/bin/env bash
set -euo pipefail       # exit immediately in case of error

# Installation of the shrink_pdf command and the "Shrink PDF" Nemo action if Nemo is detected

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
# $1 Mandatory. Exit code.
# $2 Optional.  Message for the press_any_key function. Default: "\${HIGHLIGHT}Press any key to finish...\${RESET}"
function exit_script () {
    local function_name=${FUNCNAME}
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
        echo "$(eval_gettext "\${ERR}ERROR: \${function_name} function called with incorrect number of parameter.\${RESET}" )" 1>&2
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


# Installation of a file: cp <source_path> <dest_path> then (optional) chmod "$3" <dest_path>
# $1 Mandatory. Description of the file. Example "Main command", "French translation", etc.
# $2 Mandatory. Source path.
# $3 Mandatory. Destination path.
# $4 Optional.  Access rights to set to the installed file. Example: "u=rwx,g=rx,o=rx"
function install_file () {
    local function_name=${FUNCNAME}
    if [ $# -lt 3 ] || [ $# -gt 4 ]; then
        echo "$(eval_gettext "\${ERR}ERROR: \${function_name} function called with incorrect number of parameter.\${RESET}" )" 1>&2
        exit_script 255    # bug: function called with incorrect parameter
    fi
    local file_description=$1
    local src_path=$2
    local dest_path=$3

    if [ ! -f "${src_path}" ]; then
        echo "$(eval_gettext "\${ERR}ERROR: \${function_name} function called with a wrong parameter.\${RESET}" )" 1>&2
        exit_script 255    # bug: function called with incorrect parameter
    fi
    echo -n "$( eval_gettext "Installation of \${file_description}: \"\${dest_path}\"... " )"
    if ! sudo cp "${src_path}" "${dest_path}" ; then
        echo "$(eval_gettext "\${ERR}ERROR: failed to install the file.\${RESET}" )" 1>&2
        exit_script 2   # Installation failure
    fi
    if [ $# -eq 4 ]; then
        local access_rights=$4
        if ! sudo chmod "${access_rights}" "${dest_path}" ; then
            echo "$(eval_gettext "\${ERR}ERROR: failed to set access rights to the file.\${RESET}" )" 1>&2
            exit_script 2   # Installation failure
        fi
    fi
    echo "$(gettext "ok.")"
}

# Create the directory tree of a FILE: mkdir -p <directory_tree> then (optional)
# $1 Mandatory. FILE path. The file name will be removed to create its directory tree.
function mktree () {
    local function_name=${FUNCNAME}
    if [ $# -ne 1 ]; then
        echo "$(eval_gettext "\${ERR}ERROR: \${function_name} function called with incorrect number of parameter.\${RESET}" )" 1>&2
        exit_script 255    # bug: function called with incorrect parameter
    fi
    local directory_tree=$(dirname "$1")

    if [ ! -d "${directory_tree}" ]; then
        echo -n "$( eval_gettext "Creation of the directory tree \"\${directory_tree}\"... " )"
        if ! sudo mkdir -p "${directory_tree}" ; then
            echo "$(eval_gettext "\${ERR}ERROR: failed to create the directory tree.\${RESET}" )" 1>&2
            exit_script 2   # Installation failure
        else
            echo "$(gettext "ok.")"
        fi
    fi
}


# Source directory: where is this script currently running
SOURCE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Name of the script ot install
SCRIPT_FILENAME="shrink_pdf"

NEMO_ACTION_MENU="$(gettext "Shrink PDF")"


# Error exit if "gs" is not installed (Ghostscript command)
command -v gs  1>/dev/null 2>&1 || {
    echo "$(eval_gettext "\${ERR}ERROR: The \"gs\" command is required but not installed. (Ghostscript)\${RESET}" )" 1>&2
    exit_script 253       # Error: missing prerequisite
}

# Error exit if "bc" is not installed (Basic Calculator)
command -v bc  1>/dev/null 2>&1 || {
    echo "$(eval_gettext "\${ERR}ERROR: The \"bc\" command is required but not installed. (Basic Calulator)\${RESET}" )" 1>&2
    exit_script 253       # Error: missing prerequisite
}

# Is Nemo present?
if command -v nemo 1>/dev/null 2>&1 ]; then 
    NEMO_PRESENT=true
else
    NEMO_PRESENT=false
fi

# Install confirmation
echo
echo "$( eval_gettext "This will install the shell command \"\${SCRIPT_FILENAME}\"." )"
if [ "${NEMO_PRESENT}" = "true" ]; then
    echo "$( eval_gettext "This will also install a new \"\${NEMO_ACTION_MENU}\" context menu entry (\"right-click\") in Nemo, the file manager, for PDF files." )"
else
    echo "$( eval_gettext "The file manager Nemo has NOT been detected. If you install it later, you will see a \"\${NEMO_ACTION_MENU}\" context menu entry (\"right-click\") of PDF files." )"
fi
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Canceled, ok.")"
    exit_script 0
fi 

echo

# Ask for elevated privileges (sudo)
echo -n "$( gettext "You need elevated privileges to install: " )"
sudo -v
if [ $? -ne 0 ]; then
    echo "$( gettext "\${ERR}ERROR: Installation canceled: Failed to get elevated privileges (sudo).\${RESET}" )"
    exit_script 253       # Error: missing prerequisite
fi
echo "$( gettext "ok for elevated privileges (sudo).")"

echo

# Install the script for all users of the system, in /usr/bin (should be in $PATH)
file_description="$( gettext "the main command" )"
source_file_path="${SOURCE_DIR}/${SCRIPT_FILENAME}"
dest_file_path="/usr/bin/${SCRIPT_FILENAME}"
install_file "${file_description}" "${source_file_path}" "${dest_file_path}"

# files and directory for translation files of the script
LOCALE_FILE_NAME="shrink_pdf.mo"
LOCALE_DIRECTORY="/usr/share/locale"

# Install the 'fr' translation files of the script for all users of the system, in /usr/share/locale
file_description="$( gettext "the French translation" )"
lang="fr"
source_file_path="${SOURCE_DIR}/locale/${lang}/LC_MESSAGES/${LOCALE_FILE_NAME}"
dest_file_path="${LOCALE_DIRECTORY}/${lang}/LC_MESSAGES/${LOCALE_FILE_NAME}"
install_file "${file_description}" "${source_file_path}" "${dest_file_path}"


# Install the Nemo action for all users of the system
file_description="$( eval_gettext "the Nemo action \"\${NEMO_ACTION_MENU}\"" )"
nemo_action_filename="shrink_pdf.nemo_action"
source_file_path="${SOURCE_DIR}/${nemo_action_filename}"
dest_file_path="/usr/share/nemo/actions/${nemo_action_filename}"
mktree "${dest_file_path}"      # create the directory tree if needed (Nemo not installed yet)
install_file "${file_description}" "${source_file_path}" "${dest_file_path}"

# Install the English man page for all users of the system
file_description="$( gettext "the English man page" )"
man_page_en_filename="${SCRIPT_FILENAME}.1.gz"
source_file_path="${SOURCE_DIR}/man/${man_page_en_filename}"
dest_file_path="/usr/share/man/man1/${man_page_en_filename}"
install_file "${file_description}" "${source_file_path}" "${dest_file_path}"


# Install the French man page for all users of the system
file_description="$( gettext "the French man page" )"
lang="fr"
source_file_path="${SOURCE_DIR}/man/${SCRIPT_FILENAME}.${lang}.1.gz"
dest_file_path="/usr/share/man/${lang}/man1/${SCRIPT_FILENAME}.1.gz"
install_file "${file_description}" "${source_file_path}" "${dest_file_path}"


# The End
echo
echo "$(gettext "The installation succeeded.")"
if [ "${NEMO_PRESENT}" = "true" ]; then
    echo "$( eval_gettext "You may have to close and relaunch the file manager Nemo to use the new \"\${NEMO_ACTION_MENU}\" context menu entry for PDF files." )"
fi

press_any_key
exit 0
