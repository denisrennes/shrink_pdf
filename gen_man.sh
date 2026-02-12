#!/usr/bin/env bash

# Generate the man pages for shrink_pdf in ENglish eand French, using help2man

# For translations of this installation script
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
export TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"


# Display a given message then waits for any key to be pressed, then return
# $1: Optional message to display. Default: "Press any key...'"
function press_any_key () {
    echo
    if [[ -z ${1} ]]; then
        echo "$(gettext "Press any key...")"
    else
        echo "${1}"
    fi
    read -s -n 1 
}

# User input y or : Continue? y or n: exit 0 (success) if y, or 1 (failure) if n
# $1 is the text prompt. (' [y/n]' is appended)
# exit 0 if y/Y
# exit 1 if n/N
function yes_or_no () {
    yn_p="${1}""$(gettext " [y/n]: ")"
    while true; do
        read -n 1 -p "${yn_p}" yn
        echo
        case ${yn^^} in
            "$(gettext "Y")") return 0 ;;  
            "$(gettext "N")") return 1 ;;  
        esac
    done
}


# Source directory: where is this script currently running
source_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# install location for the script
script_filename="shrink_pdf"

# Install confirmation
echo
echo "$( eval_gettext "This will generate the English and French man pages for \"\${script_filename}\"." )"
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Canceled, ok.")"
    exit 2
fi 

echo

# Generate the English man page
file_name="${script_filename}.1"
help2man --no-info "${script_filename}" >"${source_dir}/${file_name}"
source_file_path="${source_dir}/${file_name}"
if [ -f "${source_file_path}.gz" ]; then
    rm "${source_file_path}.gz"
fi
gzip "${source_file_path}"

# The End
echo
echo "$(gettext "ok.")"

press_any_key
exit 0

