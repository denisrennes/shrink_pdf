#!/usr/bin/env bash

# Try to shrink the size of PDF files, using a Ghostscript command. See: https://www.digitalocean.com/community/tutorials/reduce-pdf-file-size-in-linux
# All arguments are PDF files to shrink, if possible.

# For translation
. gettext.sh
export TEXTDOMAIN="$(basename "$0" '.sh')"
export TEXTDOMAINDIR="$(cd "$(dirname "$0")" && pwd)/locale"


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
        echo $(gettext "Press any key...")
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


##### MAIN #####

TEMP_SHRINKED_SUBEXT=".TEMP_SHRINKED"                    # The temporary name of the shrinked file will end with ".${TEMP_SHRINKED_SUBEXT}.pdf"
ORIGINAL_NOT_SHRINKED_SUBEXT=".ORIGINAL_NOT_SHRINKED"    # The new name of the original (not shrinked) PDF file will end with ".${ORIGINAL_NOT_SHRINKED_SUBEXT}.pdf"

# Process every file provided as arguments
for input_file in "$@"
do
    filesize_input_file=$(stat -c%s "${input_file}")                # size of the original file
    echo
    echo -n "Shrink the PDF file '${input_file}', $(divide_by_1000 ${filesize_input_file} 1) kB ... "
    
    file_extension="$(file_extension "${input_file}")"                  # file extension
    filepath_minus_ext="$(path_without_extension "${input_file}")"      # input file path without extension

    # normal case: the input file has not been already processed and renamed by this script
    source_file="${input_file}"
    result_file="${filepath_minus_ext}${TEMP_SHRINKED_SUBEXT}${file_extension}"         # The temporary name of the result file. It will be later renamed as the original source file name.
    bak_file=${filepath_minus_ext}${ORIGINAL_NOT_SHRINKED_SUBEXT}${file_extension}      # The new name of the original PDF file. Its current name will be used by the result shrinked PDF file.

    re_shrink='false'   # normal case: the source file will be shrinked for the first time, then renamed

    # If the original (renamed) file exists then skip this file: it is the result of a previous shrinking by this script
    if [[ -f "${bak_file}" ]]; then 
        echo "skipped because it is already a shrinked result file."
        echo "    The original file is '$(file_name "${bak_file}")'"
        continue        # next file
    fi

    # If it is an original file that was previously processed by this script, so if it is already renamed .${ORIGINAL_NOT_SHRINKED_SUBEXT}${file_extension}) then
    #   if the result file still exists then do nothing, proceed with the next file
    #   if the result file no longer exists then shrink this file again: source is the input file already renamed, result is the original name and they will not be renamed again
    extension2="$(file_extension "${filepath_minus_ext}")"      # second extension
    if [[ "${extension2}" == "${ORIGINAL_NOT_SHRINKED_SUBEXT}" ]]; then
        filepath_minus_ext_minus_ext="$(path_without_extension "${filepath_minus_ext}")"    # remove the second extension ".${ORIGINAL_NOT_SHRINKED_SUBEXT}"
        previous_result_file="${filepath_minus_ext_minus_ext}${file_extension}"
        if [[ -f "${previous_result_file}" ]]; then
            echo "skipped because already shrinked before."
            echo "    The shrinked file is: '$(file_name "${previous_result_file}")'"
            continue        # next file
        else
            # specific case: the source file has been previously already shrinked and renamed by this script. It will be shrinked again but not renamed because already renamed
            re_shrink='true'
            result_file="${previous_result_file}"
        fi
    fi
 
    # if the result file already exists, delete it
    if [[ -f "${result_file}" ]]; then
        rm "${result_file}"
    fi

    # Use a Ghostscript command to shrink the PDF file
    # The resulting PDF file could be even smaller by using the argument “-dPDFSETTINGS=/screen,” though this would result in a loss of quality (that many consider acceptable).
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="${result_file}" "${input_file}"
    exit_code=$?

    # if the exit code is not 0 then display an error, delete the temporary result file (if any), then continue with the next file
    if (( ${exit_code} != 0 )); then
        echo "ERROR: exit code ${exit_code} returned by the 'gs' command (Ghostscript)."
        if [[ -f "${result_file}" ]]; then
            rm "${result_file}"
        fi
        continue
    fi
    # if the result temporay file does not exist, display an error, then continue with the next file
    if [[ ! -f "${result_file}" ]]; then
        echo "ERROR: something went wrong, the result file does not exist."
        continue
    fi

    # Verify that the result file is actually smaller than the original: 
    # if so, rename the source file as a "bak" file and the result file as the original file name, UNLESS it is a specific re-shrink case (renaming alredy done previously)
    # else delete the result file: the source file was already small
    filesize_result_file=$(stat -c%s "${result_file}")        # size of the result file
    if (( ${filesize_result_file} <= ${filesize_input_file} )); then
        if [[ ${re_shrink} != 'true' ]]; then
            mv "${input_file}" "${bak_file}"            # rename the source file as a "bak" file
            gio trash "${bak_file}"                     # move the (renamed) source file to the trash
            mv "${result_file}" "${input_file}"         # rename the shrinked file as the original file name
            echo "ok: now $(divide_by_1000 ${filesize_result_file} 1) kB."
            echo "    The original file has been renamed '$(file_name "${bak_file}")' ."
        else
            echo "ok: now the result file is $(divide_by_1000 ${filesize_result_file} 1) kB."
            echo "    The result file is '$(file_name "${result_file}")' ."
        fi
    else
        rm "${result_file}"
        echo "This PDF file is already small."
    fi
    
done

press_any_key $(gettext "Press any key to exit...")
exit 0
