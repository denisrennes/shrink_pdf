#!/usr/bin/env bash

# Installation of the "PDF shrink" Nemo action 

# Display a given message then waits for any key to be pressed, then return
# $1: Optional message to display. Default: "Press any key...'"
function press_any_key () {
    if [ -z "$1" ]; then
        echo 'Press any key...'
    else
        echo "${1}"
    fi
    read -s -n 1 
}

# Source directory: where is this script currently running
source_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Install the script for all users of the system, in /usr/local/bin (should be in $PATH)
file_name=shrink_pdf.sh
dest_file_path=/usr/local/bin/${file_name}
echo -n "Install \"${file_name}\" to \"${dest_file_path}\" ... "
sudo cp "${source_dir}/${file_name}" "${dest_file_path}"
sudo chmod u=rwx,g=rx,o=rx "${dest_file_path}"
echo "ok."

# check with which command


# Install the Nemo action for all users of the system
file_name=shrink_pdf.nemo_action
dest_file_path=/usr/share/nemo/actions/${file_name}
echo -n "Install \"${file_name}\" to \"${dest_file_path}\" ... "
sudo cp "${source_dir}/${file_name}" "${dest_file_path}"
sudo chmod u=rw,g=r,o=r "${dest_file_path}"
echo "ok."

# The End
echo
echo "You may have to close and relaunch the file manager Nemo to use the new \"PDF shrink\" context menu (a.k.a. "right click menu") for PDF files."

press_any_key "Press any key to exit..."
exit 0

