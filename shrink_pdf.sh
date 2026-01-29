#!/usr/bin/env bash

# Try to shrink the size of PDF files, using a Ghostscript command. See: https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux
# All arguments are PDF files to shrink. They can be passed by a file manager custom context menu actions, like Nemo actions.

# If the size of the PDF file has actually been reduced (at least 1 % shrinked), then the original file is renamed ‘.ORIGINAL.pdf’ and the new compressed file takes its name.
# If the PDF file could not be reduced in size, it means it is already optimized. This tool will detect this and display a message, leaving the original PDF file unchanged.

# For translations
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"
if [ ! -d ${TEXTDOMAINDIR} ]; then
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
    echo "scale=$2; $1/1000" | bc -l
}

# Compute the shrink percentage
# $1 is the original size
# $2 is the new size
# Return the result to the Standard Output
# Example: return "96.8" if $1 is 5808000 and $2 is 184000
function shrink_percent () {
    if (( $# != 2 )); then
        return 255
    fi
    echo "scale=1; 100-$2*100/$1" | bc -l
}


##### MAIN ####

# parsing arguments: "--press_any_key" or a file path
press_any_key=false
files=()
for arg in "$@"; do
    case "$arg" in
        --press_any_key)
            press_any_key=true
            ;;
        --* | -*)
            echo "$(eval_gettext "ERROR: Incorrect command line argument \"\${arg}\"." )" >&2
            exit 1
            ;;
        *)
            files+=("$arg")
            ;;
    esac
done



TEMP_SHRINKED_SUBEXT="$(gettext ".TEMP_SHRINKED")"      # The temporary name of the shrinked file will end with ".TEMP_SHRINKED.pdf"
ORIGINAL_SUBEXT="$(gettext ".ORIGINAL")"                # "bak" file name: the new name of the original PDF file will end with ".ORIGINAL.pdf"

# Process every file provided as arguments
for input_file in "${files[@]}"
do
    echo

    file_extension="$(file_extension "${input_file}")"                  # file extension
    filepath_minus_ext="$(path_without_extension "${input_file}")"      # input file path without extension

    # normal case: the input file has NOT been already processed and renamed by this script
    source_file="${input_file}"
    result_file="${filepath_minus_ext}${TEMP_SHRINKED_SUBEXT}${file_extension}"     # The temporary name of the result file. It will be later renamed as the original source file name.
    bak_file=${filepath_minus_ext}${ORIGINAL_SUBEXT}${file_extension}               # The future name of the original PDF file (It will be renamed if the shrinking is successful)
    bak_file_filename="$(file_name "${bak_file}")"

    # Skip the file if its corresponding original file (renamed as a "bak" file) exists in the same directory
    if [[ -f "${bak_file}" ]]; then
        msg="$( eval_gettext "\"\${input_file}\" is skipped because it is probably the shrinked result of \"\${bak_file_filename}\"" )"
        echo "${msg}"
        continue        # next file
    fi

    # Skip the file if it is a file already renamed .${ORIGINAL_SUBEXT}${file_extension}): it is an original file previously processed by this script.
    extension2="$(file_extension "${filepath_minus_ext}")"      # second extension
    if [[ "${extension2}" == "${ORIGINAL_SUBEXT}" ]]; then
        echo "$( eval_gettext "\"\${input_file}\" is skipped because it has been already shrinked before. To shrink it again, rename it to its original name." )"
        continue        # next file
    fi

    filesize_input_file=$(stat -c%s "${input_file}")                        # size of the original file
    filesize_input_file_kB="$(divide_by_1000 ${filesize_input_file} 1)"     # size of the original file in kB
    
    echo -n "$( eval_gettext "\"\${input_file}\", \${filesize_input_file_kB} kB ... " )"
 
    # if the result file already exists (with its temporary name), then delete it. It could be the result of a previous shrinking attempt, interrupted before the renaming step.
    if [[ -f "${result_file}" ]]; then
        rm "${result_file}"
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: unable to delete \"\${result_file}\" before starting shrinking." )" >&2
            continue    # next file
        fi
    fi

    # Use a Ghostscript command to shrink the PDF file
    # The result file could be even smaller by using the argument “-dPDFSETTINGS=/screen,” though with a higher loss of quality (that many still consider acceptable).
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${result_file}" "${input_file}"
    exit_code=$?

    # if the exit code is not 0 then display an error, delete the temporary result file (if any), then continue with the next file
    if (( ${exit_code} != 0 )); then
        echo "$( eval_gettext "ERROR: The shrinking command returned an error (exit code \${exit_code} returned by 'gs', a command from Ghostscript)." )" >&2
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

    # Verify that the result file is at least 1% smaller than the original: 
    # if so, rename the source file as a "bak" file and the result file will replace it, taking its name, 
    # else delete the result file: the source file was already small
    filesize_result_file=$(stat -c%s "${result_file}")                              # size of the result file
    filesize_result_file_kB="$(divide_by_1000 ${filesize_result_file} 1)"           # size of the result file in kB
    shrink_pc="$(shrink_percent ${filesize_input_file} ${filesize_result_file})"    # shrink percentage

    if (( $(echo "$shrink_pc >= 1" | bc -l) )); then   # Is the shrink percentage higher or equal to 1 % ?

        # ok successful shrinking
        mv "${input_file}" "${bak_file}"            # rename the source file as a "bak" file
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: something went wrong after shrinking. Unable to rename the original file as \"\${bak_file}\"." )" >&2
        fi

        mv "${result_file}" "${input_file}"         # rename the shrinked file as the original file name
        if (($? != 0 )); then
            echo "$( eval_gettext "ERROR: something went wrong after shrinking. Unable to renamed the temporary result file name \"\${result_file}\" as the original file name." )" >&2
        fi

        echo "$( eval_gettext "ok: now \${filesize_result_file_kB} kB ( ${shrink_pc} % shrinked )." )"
        echo "$( eval_gettext "The original unshrinked file is now renamed \"\${bak_file_filename}\" ." )"
    else

        # shrinking failed: the shrink percentage is less than 1%
        rm "${result_file}" 1>/dev/null 2>&1
        echo "$( gettext "This PDF file is already small." )"
    fi
    
done

if [ ${press_any_key} = true ]; then press_any_key "$( gettext "Press any key to exit..." )"; fi
exit 0
