#!/usr/bin/env bash
set -euo pipefail       # exit immediately in case of error

# Installation of the shrink_pdf command and the "Shrink PDF" Nemo action if Nemo is detected

# For translations of this installation script
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
export TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"


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


# Source directory: where is this script currently running
source_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# install location for the script
script_filename="shrink_pdf"
script_directory="/usr/bin"
# install location for the translation files of the script
locale_file_filename="shrink_pdf.mo"
locale_directory="/usr/share/locale"
# install location for the Nemo action
nemo_action_filename="shrink_pdf.nemo_action"
nemo_actions_directory="/usr/share/nemo/actions"
nemo_action_menu="$(gettext "Shrink PDF")"
# install location for the English man page file
man_page_en_filename="shrink_pdf.nemo_action"
man_page_en_directory="/usr/share/man/man1"
# install location for the French man page file
Man_page_fr_directory="/usr/share/man/fr/man1"


# Error exit if "gs" is not installed (Ghostscript command)
command -v gs >/dev/null 2>&1 || {
    echo "$(gettext "ERROR: The \"gs\" command is required but not installed. (Ghostscript)" )" >&2
    exit 1
}

# Error exit if "bc" is not installed (Basic Calculator)
command -v bc >/dev/null 2>&1 || {
    echo "$(gettext "ERROR: The \"bc\" command is required but not installed. (Basic Calulator)" )" >&2
    exit 1
}

# Is Nemo present?
if command -v nemo 1>/dev/null 2>&1 && [ -d "${nemo_actions_directory}" ]; then 
    nemo_present=true
else
    nemo_present=false
fi

# Install confirmation
echo
echo "$( eval_gettext "This will install a shell command \"\${script_filename}\"." )"
if [ "${nemo_present}" = "true" ]; then
    echo "$( eval_gettext "This will also install a new \"\${nemo_action_menu}\" context menu entry (\"right-click\") in Nemo, the file manager, for PDF files." )"
else
    echo "$( eval_gettext "As the file manager Nemo has NOT been detected, this will NOT install a new \"\${nemo_action_menu}\" context menu entry (\"right-click\") in Nemo, for PDF files." )"
fi
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Canceled, ok.")"
    exit 2
fi 

echo

# Ask for elevated privileges (sudo)
echo -n "$( gettext "We need elevated privileges to install: " )"
sudo -v
if [ $? -ne 0 ]; then
    echo "$( gettext "Installation canceled: Failed to get elevated privileges (sudo)." )"
    exit 1
fi
echo "$( gettext "ok for elevated privileges (sudo).")"

echo

# Install the script for all users of the system, in /usr/bin (should be in $PATH)
file_name="${script_filename}"
source_file_path="${source_dir}/${file_name}"
dest_directory="${script_directory}"
dest_file_path="${dest_directory}/${script_filename}"
echo -n "$( eval_gettext "Installation of \"\${file_name}\" to \"\${dest_directory}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rwx,g=rx,o=rx "${dest_file_path}"
echo "$(gettext "ok.")"

# Install the English man page for all users of the system
file_name="${script_filename}.1.gz"
source_file_path="${source_dir}/${file_name}"
dest_directory="${man_page_en_directory}"
dest_file_path="${dest_directory}/${file_name}"
echo -n "$( eval_gettext "Installation of \"\${file_name}\" to \"\${dest_directory}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rw,g=r,o=r "${dest_file_path}"
echo "$(gettext "ok.")"

# Install the 'fr' translation files of the script for all users of the system, in /usr/share/locale
lang="fr"
file_name="${locale_file_filename}"
source_file_path="${source_dir}/locale/${lang}/LC_MESSAGES/${file_name}"
dest_directory="${locale_directory}/${lang}/LC_MESSAGES"
dest_file_path="${dest_directory}/${locale_file_filename}"
echo -n "$( eval_gettext "Installation of \"\${file_name}\" to \"\${dest_directory}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rw,g=r,o=r "${dest_file_path}"
echo "$(gettext "ok.")"

# If Nemo is present, install the Nemo action for all users of the system
if [ "${nemo_present}" = "true" ]; then
    file_name="${nemo_action_filename}"
    source_file_path="${source_dir}/${file_name}"
    dest_directory="${nemo_actions_directory}"
    dest_file_path="${dest_directory}/${nemo_action_filename}"
    echo -n "$( eval_gettext "Installation of \"\${file_name}\" to \"\${dest_directory}\" ... " )"
    sudo cp "${source_file_path}" "${dest_file_path}"
    sudo chmod u=rw,g=r,o=r "${dest_file_path}"
    echo "$(gettext "ok.")"
fi

# The End
echo
echo "$(gettext "The installation succeeded.")"
if [ "${nemo_present}" = "true" ]; then
    echo "$( eval_gettext "You may have to close and relaunch the file manager Nemo to use the new \"\${nemo_action_menu}\" context menu entry for PDF files." )"
fi

press_any_key
exit 0

