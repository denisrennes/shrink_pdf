#!/usr/bin/env bash

# Generate translation files for a bash script using gettext
# $1 The bash script path. Mandatory. 
# $2 The language. ex: 'fr', 'fr-FR'. Mandatory.
# Generates a .mo and .po translation files in the sub-directory ./locale/<short_lang>/LC_MESSAGES, relative to the script path.

# $1 and $2 are mandatory
if (( $# != 2 )); then
  echo "ERROR: 2 arguments are mandatory: The bash script path and the short language (ex:"fr")"
  exit 255
fi

# check arg 1: must be an existing bash script path with a '.sh' extension
script_path="${1}"
if [[ ! -f "${script_path}" ]]; then
  echo "ERROR: argument 1 must be an existing bash script path, with \".sh\" extension."
  exit 255
fi
script_name="$(basename "${script_path}")"
script_nameonly="$(basename "${script_path}" ".sh")"
if [[ "${script_nameonly}" == "${script_name}" ]]; then
  echo "ERROR: argument 1 must be a bash script path, with a \".sh\" extension."
  exit 255
fi

# check arg 2: must be a language code, like 'fr', 'fr_FR', etc.
lang="${2}"
echo "${lang}" | grep -E '^[a-zA-Z]{1,2}(_[A-Z]{2})?(\.utf8)?$' 1>/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: argument 2 must be a a language code, like 'fr', 'fr_FR', etc."
  exit 255
fi
  
# Future TEXTDOMAIN and TEXDOMAINDIR for gettext in this language
textdomain="$(basename "$1" '.sh')"
textdomaindir="$(cd "$(dirname "$1")" && pwd)/locale"

echo

# Generate the .pot file, the template file for .mo files
source_file="${textdomain}.sh"
result_file="${textdomain}.pot"
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

# Create the destination directory for the translation files .po and .mo
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

# Create or update the .po file for this language
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

# Convert the .mo file from the .po file (only .po files are used by gettext tools)
source_file=${result_file}
result_file="${lang_msg_dir}/${textdomain}.mo"
echo -n "Generate '${result_file}' from '${source_file}'... "
msgfmt "${source_file}" -o "${result_file}"
if [[ $? == 0 ]]; then echo 'ok'; else echo 'ERROR!'; exit 20; fi 

echo
echo "To test this language translation, just launch this command line: 'LANGUAGE=${lang} ./${textdomain}.sh' [... arguments]"

