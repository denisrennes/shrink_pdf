#!/usr/bin/env bash

# Try to shrink the size of PDF files, using a Ghostscript command. See: https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux
# All arguments are PDF files to shrink. They can be passed by a file manager custom context menu actions, like Nemo actions.

# If the PDF file has been reduced in size, it will replace the original. The original file is renamed "... .ORIGINAL.pdf" and moved to the Trash.
# If the PDF file could not be reduced in size, it means it is already optimized. This tool will detect this and display a message, leaving the original PDF file unchanged.

# For translations
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"
if [ ! -d ${TEXTDOMAINDIR} ]: then
    TEXTDOMAINDIR="/usr/share/locale"
fi
export TEXTDOMAINDIR


##### FUNCTIONS #####


# File base name, with the extension, if any
# $1 is the file path
# Result is returned via stdout
function file_name () {
    echo "${1##*/}"
}

# File Extension, if any. Example: '.pdf' 
# $1 is the file path
# Result is returned via stdout
# A '.' as first character of the file name is discarded for the search of the file extension. Ex: '.conf': no extension, '.conf.json':'.json' extension 
# When no extension, '' is returned
function file_extension () {
    local filename

    # Extract filename from path
    filename="$(file_name "${1}")"

    # If filename starts with a dot, remove it: it does not mean an extension
    if [[ "$filename" == .* ]]; then
        filename="${filename##.}"
    fi

    # If filename contains a dot, extract the extension
    if [[ "$filename" == *.* ]]; then
        echo ".${filename##*.}"
    else
        echo ''
    fi
}

# Removes the extension of a file path (the starting '.' is removed too)
# $1 is the file path
# Result is returned via stdout
function path_without_extension () {
    local file=${1}
    local ext="$(file_extension "${file}")"      # the file extension
    # remove the n last characters, n is file extension length
    if [[ -z ${ext} ]]; then 
        echo "${file}"
    else
        echo "${file::-$((${#ext}))}"
    fi
}

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

# Divide a number by 1000 with a required number of digits after the decimal point
# $1 is the number to divide by 1000
# $2 is the required number of digits after the decimal point
# Return the result to the Standard Output
function divide_by_1000 () {
    if (( $# != 2 )); then
        return 255
    fi
    echo $(echo "scale=$2; $1/1000" | bc) 
}


##### MAIN ####

TEMP_SHRINKED_SUBEXT="$(gettext ".TEMP_SHRINKED")"      # The temporary name of the shrinked file will end with ".${TEMP_SHRINKED_SUBEXT}.pdf"
ORIGINAL_SUBEXT="$(gettext ".ORIGINAL")"                # The new name of the original (not shrinked) PDF file will end with ".${ORIGINAL_SUBEXT}.pdf"

# Process every file provided as arguments
for input_file in "$@"
do
    echo

    file_extension="$(file_extension "${input_file}")"                  # file extension
    filepath_minus_ext="$(path_without_extension "${input_file}")"      # input file path without extension

    # normal case: the input file has NOT been already processed and renamed by this script
    source_file="${input_file}"
    result_file="${filepath_minus_ext}${TEMP_SHRINKED_SUBEXT}${file_extension}"     # The temporary name of the result file. It will be later renamed as the original source file name.
    bak_file=${filepath_minus_ext}${ORIGINAL_SUBEXT}${file_extension}               # The future name of the original PDF file (It will be renamed if the shrinking is successful)
    bak_file_filename="$(file_name "${bak_file}")"

    # Skip the file if its corresponding original file (renamed) exists in the same directory (probably restored from the Trash)
    if [[ -f "${bak_file}" ]]; then
        msg="$( eval_gettext "The file \"\${input_file}\" is skipped because it is probably the shrinked result of \"\${bak_file_filename}\"" )"
        echo "${msg}"
        continue        # next file
    fi

    # Skip the file if it is a file already renamed .${ORIGINAL_SUBEXT}${file_extension}): it is an original file previously processed by this script, then probably restored from the Trash.
    extension2="$(file_extension "${filepath_minus_ext}")"      # second extension
    if [[ "${extension2}" == "${ORIGINAL_SUBEXT}" ]]; then
        echo "$( eval_gettext "The file \"\${input_file}\" is skipped because it has been already shrinked before. To shrink it again, rename it to its original name." )"
        continue        # next file
    fi

    filesize_input_file=$(stat -c%s "${input_file}")                        # size of the original file
    filesize_input_file_kB="$(divide_by_1000 ${filesize_input_file} 1)"     # size of the original file in kB
    
    echo -n "$( eval_gettext "Shrink the PDF file \"\${input_file}\", \${filesize_input_file_kB} kB ... " )"
 
    # if the result file already exists (with its temporary name), then delete it. It could be the result of a previous shrinking attempt, interrupted before the renaming step.
    if [[ -f "${result_file}" ]]; then
        rm "${result_file}"
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: unable to delete \"\${result_file}\" before starting shrinking." )"
            continue    # next file
        fi
    fi

    # Use a Ghostscript command to shrink the PDF file
    # The result file could be even smaller by using the argument “-dPDFSETTINGS=/screen,” though with a higher loss of quality (that many still consider acceptable).
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${result_file}" "${input_file}"
    exit_code=$?

    # if the exit code is not 0 then display an error, delete the temporary result file (if any), then continue with the next file
    if (( ${exit_code} != 0 )); then
        echo "$( eval_gettext "ERROR: The shrinking command returned an error (exit code \${exit_code} returned by 'gs', a command from Ghostscript)." )"
        # if the result file exists, delete it because it is probably corrupted (it happens sometimes with 'gs')
        if [[ -f "${result_file}" ]]; then
            rm "${result_file}" 1>/dev/null 2>&1
        fi
        continue   # next file
    fi
    # if the result temporay file does not exist, display an error, then continue with the next file
    if [[ ! -f "${result_file}" ]]; then
        echo "$( gettext "ERROR: something went wrong, no shrinking result file." )"
        continue   # next file
    fi

    # Verify that the result file is actually smaller than the original: 
    # if so, rename the source file as a "bak" file and the result file will replace it, taking its name, UNLESS it is a specific re-shrink case (renaming already done previously)
    # else delete the result file: the source file was already small
    filesize_result_file=$(stat -c%s "${result_file}")                      # size of the result file
    filesize_result_file_kB="$(divide_by_1000 ${filesize_result_file} 1)"   # size of the result file in kB

    if (( ${filesize_result_file} <= ${filesize_input_file} )); then

        # ok successful shrinking
        mv "${input_file}" "${bak_file}"            # rename the source file as a "bak" file
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: something went wrong after shrinking. Unable to rename the original file as \"\${bak_file}\"." )"
        fi

        gio trash "${bak_file}"                     # move the (renamed) source file to the trash
        if (($? != 0 )); then
            echo "$( gettext "ERROR: something went wrong after shrinking. Unable to move the renamed original file to the Trash." )"
        fi

        mv "${result_file}" "${input_file}"         # rename the shrinked file as the original file name
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: something went wrong after shrinking. Unable to renamed the temporary result file name \"\${result_file}\" as the original file name." )"
        fi

        echo "$( eval_gettext "ok: now \${filesize_result_file_kB} kB." )"
        echo "$( eval_gettext "The original unshrinked file is now in the Trash, renamed \"\${bak_file_filename}\" ." )"
    else

        # shrinking failed: the result is not smaller
        rm "${result_file}" 1>/dev/null 2>&1
        echo "$( gettext "This PDF file is already small." )"
    fi
    
done

press_any_key "$( gettext "Press any key to exit..." )"
exit 0
