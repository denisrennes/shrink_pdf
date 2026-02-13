#!/usr/bin/env bash
set -euo pipefail       # exit immediately in case of error

# Generate the man pages for shrink_pdf in ENglish eand French, using help2man

# For translations of this installation script
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
export TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"


# Display a given message then waits for any key to be pressed, then return
# $1: Optional message to display. Default: "Press any key...'"
function press_any_key () {
    echo
    if [ $# -ge 1 ]; then
        echo "${1}"
    else
        echo "$(gettext "Press any key...")"
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

script_filename="shrink_pdf"

man_dir="${source_dir}/man"


# confirmation
echo
echo "$( eval_gettext "This will generate the English and French man pages for \"\${script_filename}\"." )"
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Canceled, ok.")"
    exit 2
fi 

echo

echo -n "Generate the English man page... "
man_file_name="${script_filename}.1"
man_gz_file_name="${man_file_name}.gz"
if [ -f "${man_dir}/${man_gz_file_name}" ]; then
    rm "${man_dir}/${man_gz_file_name}"
fi
gzip -k "${man_dir}/${man_file_name}"
echo "ok."

echo

echo -n "Generate the French man page... "
lang="fr"
man_file_name="${script_filename}.${lang}.1"
man_gz_file_name="${man_file_name}.gz"
if [ -f "${man_dir}/${man_gz_file_name}" ]; then
    rm "${man_dir}/${man_gz_file_name}"
fi
gzip -k "${man_dir}/${man_file_name}"
echo "ok."


# The End
echo
echo "$(gettext "OKAY.")"

press_any_key
exit 0

