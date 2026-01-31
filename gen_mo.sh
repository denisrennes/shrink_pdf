#!/usr/bin/env bash

# Generate translation files for a Bash script using gettext tools.
# $1 The bash script path. Mandatory. 
# $2 The language. ex: 'fr', 'fr-FR'. Mandatory.
# 
# Steps:
# 1) All 'gettext' 'eval_gettext' texts are extracted from the source code, the Bash script, to generate a .pot text file in the sub-directory './locale, relative to the script path.
# 2) Use the template .po file, to generate a .po translation text file for the $2 language, in the sub-directory './locale/<lang>/LC_MESSAGES', relative to the script path.
# 3) The user edits the .po file to add or modify the translated texts fo rthe $2 language.
# 4) Convert the .po text file to generate a .mo translation binary file for the $2 language, in the sub-directory ''./locale/<lang>/LC_MESSAGES', relative to the script path.
#    Only the .mo binary files are used by gettext tools at runtime.


##### SCRIPT INITIALIZATION : FUNCTIONS, VARIABLES, etc. #####

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

# Return the file name-only, i.e. the file name without the extension. The '.' of the extension is removed too.
# $1 is the file path
# Result is returned via stdout
function file_nameonly () {
    local filename="$(file_name "${1}")"
    local ext="$(file_extension "${filename}")"      # the file extension
    # remove the n last characters of the file name, n is file extension length
    if [[ -z ${ext} ]]; then 
        echo "${filename}"
    else
        echo "${filename::-$((${#ext}))}"
    fi
}


##### MAIN #####

# $1 and $2 are mandatory
if (( $# != 2 )); then
  echo "ERROR: 2 arguments are mandatory: \$1 <=> The bash script path, \$2 <=> the short language code (ex:"fr")"
  exit 255
fi

# check arg 1: must be an existing bash script path
script_path="${1}"
if [[ ! -f "${script_path}" ]]; then
  echo "ERROR: argument 1 is not an existing file path."
  exit 255
fi
mime_type="$(file --mime-type -b "${script_path}")"
if [[ ! "${mime_type}" == *"x-shellscript" ]]; then
  echo "ERROR: argument 1 must be a bash script path."
  exit 255
fi

script_name="$(file_name "${script_path}")"
script_nameonly="$(file_nameonly "${script_path}")"


# check arg 2: must be a language code, like 'fr', 'fr_FR', etc.
lang="${2}"
echo "${lang}" | grep -E '^[a-zA-Z]{1,2}(_[A-Z]{2})?(\.utf8)?$' 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: argument 2 must be a a language code, like 'fr', 'fr_FR', etc."
  exit 255
fi
  
# Future TEXTDOMAIN and TEXDOMAINDIR for gettext in this language
textdomain="${script_nameonly}"
textdomaindir="$(cd "$(dirname "${script_path}")" && pwd)/locale"

echo

# Create the destination directory for the translation files .pot, .po and .mo
lang_msg_dir="${textdomaindir}/${lang}/LC_MESSAGES"
if [[ ! -d "${lang_msg_dir}" ]]; then
  echo -n "Create the directory \"${lang_msg_dir}\": "
  mkdir -p "${lang_msg_dir}"
  if [[ $? == 0 ]]; then
    echo "ok"
  else
    echo "ERROR! Unable to create the directory for the translation files."
    exit 5
  fi
fi

echo

# Generate the .pot file, the template file for .mo files
# All 'gettext' 'eval_gettext' texts are extracted from the source code, the Bash script, to generate a .pot text file in the sub-directory './locale, relative to the script path.
source_file="${script_path}"
result_file="${textdomaindir}/${script_nameonly}.pot"
echo -n "Generate '${result_file}' from '${source_file}'... "
if [ -f "${result_file}" ]; then rm "${result_file}"; fi 
xgettext -L Shell --from-code=UTF-8 -o "${result_file}" "${source_file}"
if [ -f "${result_file}" ]; then 
  echo 'ok'
else
  echo 'ERROR! the result .pot file does not exist.'
  exit 2
fi 

# set charset as UTF-8 in the result .pot file
sed 's/charset=CHARSET/charset=UTF-8/' -i "${result_file}"

echo

# Create or update the .po file for this language
# Use the template .po file, to generate a .po translation text file for the $2 language, in the sub-directory './locale/<lang>/LC_MESSAGES', relative to the script path.
source_file="${result_file}"
result_file="${lang_msg_dir}/${textdomain}.po"
if [ -f "${result_file}" ]; then
  
  # update the .po file for this language
  echo "MERGE the new '${source_file}' with the existing ${result_file}' ... "
  msgmerge --update "${result_file}" "${source_file}"
  if [[ $? == 0 ]]; then echo 'ok'; else echo 'ERROR!'; exit 10; fi 
else

  # Create the .po file for this language, from the template .pot file
  echo "Generate '${result_file}' from '${source_file}'... "
  #msginit -l ${lang} -i "${source_file}" -o "${result_file}"
  msginit -i "${source_file}" --locale=${lang}.UTF-8 -o "${result_file}"
  if [[ $? == 0 ]]; then echo 'ok'; else echo 'ERROR!'; exit 15; fi 
fi

echo

# The user edits the .po file to add or modify the translated texts fo rthe $2 language.
source_file=${result_file}
echo
echo "You will edit the new .po file and write the translated texts into the lines 'msgstr \"\"', then save and close..."
grep 'fuzzy' "${source_file}" 1>/dev/null 2>&1
if [[ $? == 0 ]]; then
  echo "WARNING: Pay attention to the translation of msgstr lines preceded by a line marked “#, fuzzy”, and THEN DELETE THE LINE “#, fuzzy” or the translation will be ignored."
fi
echo; read -n 1 -p 'Press any key...'
xed "${source_file}"

echo

# Convert the .po text file to generate a .mo translation binary file for the $2 language, in the sub-directory ''./locale/<lang>/LC_MESSAGES', relative to the script path. 
# Only the .mo binary files are used by gettext tools at runtime.
source_file=${result_file}
result_file="${lang_msg_dir}/${textdomain}.mo"
echo -n "Generate '${result_file}' from '${source_file}'... "
msgfmt "${source_file}" -o "${result_file}"
if [[ $? == 0 ]]; then echo 'ok'; else echo 'ERROR!'; exit 20; fi 

echo
echo "To test this language translation, just launch this command line: 'LANGUAGE=${lang} ./${script_name}' [... arguments]"
