#!/usr/bin/env bash

# Installation of the shrink_pdf.sh command and the "PDF Shrink" Nemo action if Nemo is detected

# For translations
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
script_filename="shrink_pdf.sh"
script_directory="/usr/bin"
# install location for the translation files of the script
locale_file_filename="shrink_pdf.mo"
locale_directory="/usr/share/locale"
# install location for the Nemo action
nemo_action_filename="shrink_pdf.nemo_action"
nemo_actions_directory="/usr/share/nemo/actions"
nemo_action_menu="$(gettext "PDF shrink")"

# Install confirmation
echo
echo "$( eval_gettext "This will install a shell command \"\${script_filename}\" and a new \"\${nemo_action_menu}\" context menu entry (\"right-click\") in Nemo, the file manager." )"
if ! yes_or_no "$(gettext "Continue?")"; then
    echo "$(gettext "Installation canceled by the user.")"
    exit 1
fi 

# Warning if nemo is not detected
if ( command -v nemo 1>/dev/null 2>&1 ) && [ -d "${nemo_actions_directory}" ]; then 
    nemo_present="true"
else
    nemo_present="false"
    echo
    echo "$(gettext "Warning: the file manager \"Nemo\" is not detected.")" 
    echo "$( eval_gettext "If choose to continue, the shell command \"\${script_filename}\" will be available but the Nemo context menu entry ("right-click") will not be installed." )"
    if ! yes_or_no "$(getetxt "Continue?")"; then
        echo "$(gettext "Installation canceled by the user.")"
        exit 1
    fi
fi

# Install the script for all users of the system, in /usr/bin (should be in $PATH)
file_name="${script_filename}"
source_file_path="${source_dir}/${file_name}"
dest_file_path="${script_directory}/${script_filename}"
echo -n "$( eval_gettext "Install \"\${source_file_path}\" to \"\${dest_file_path}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rwx,g=rx,o=rx "${dest_file_path}"
echo "$(gettext "ok.")"

# Install the 'fr' translation files of the script for all users of the system, in /usr/share/locale
lang="fr"
file_name="${locale_file_filename}"
source_file_path="${source_dir}/locale/${lang}/LC_MESSAGES/${file_name}"
dest_file_path="${locale_directory}/${lang}/LC_MESSAGES/${locale_file_filename}"
echo -n "$( eval_gettext "Install \"\${source_file_path}\" to \"\${dest_file_path}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rw,g=r,o=r "${dest_file_path}"
echo "$(gettext "ok.")"

# Install the Nemo action for all users of the system
file_name="${nemo_action_filename}"
source_file_path="${source_dir}/${file_name}"
dest_file_path="${nemo_actions_directory}/${nemo_action_filename}"
echo -n "$( eval_gettext "Install \"\${source_file_path}\" to \"\${dest_file_path}\" ... " )"
sudo cp "${source_file_path}" "${dest_file_path}"
sudo chmod u=rw,g=r,o=r "${dest_file_path}"
echo "$(gettext "ok.")"

# The End
echo
echo "$( eval_gettext "You may have to close and relaunch the file manager Nemo to use the new \"\${nemo_action_menu}\" context menu entry for PDF files." )"

press_any_key "$(gettext "Press any key to exit...")"
exit 0

