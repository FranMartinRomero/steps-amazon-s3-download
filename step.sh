#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e

#=======================================
# Functions
#=======================================

RESTORE='\033[0m'
RED='\033[00;31m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
GREEN='\033[00;32m'

function color_echo {
	color=$1
	msg=$2
	echo -e "${color}${msg}${RESTORE}"
}

function echo_fail {
	msg=$1
	echo
	color_echo "${RED}" "${msg}"
	exit 1
}

function echo_warn {
	msg=$1
	color_echo "${YELLOW}" "${msg}"
}

function echo_info {
	msg=$1
	echo
	color_echo "${BLUE}" "${msg}"
}

function echo_details {
	msg=$1
	echo "  ${msg}"
}

function echo_done {
	msg=$1
	color_echo "${GREEN}" "  ${msg}"
}

function validate_required_input {
	key=$1
	value=$2
	if [ -z "${value}" ] ; then
		echo_fail "[!] Missing required input: ${key}"
	fi
}

function validate_required_input_with_options {
	key=$1
	value=$2
	options=$3

	validate_required_input "${key}" "${value}"

	found="0"
	for option in "${options[@]}" ; do
		if [ "${option}" == "${value}" ] ; then
			found="1"
		fi
	done

	if [ "${found}" == "0" ] ; then
		echo_fail "Invalid input: (${key}) value: (${value}), valid options: ($( IFS=$", "; echo "${options[*]}" ))"
	fi
}

#=======================================
# Main
#=======================================

#
# Validate parameters
echo_info "Configs:"
if [[ -n "$access_key_id" ]] ; then
	echo_details "* access_key_id: ***"
else
	echo_details "* access_key_id: [EMPTY]"
fi
if [[ -n "$secret_access_key" ]] ; then
	echo_details "* secret_access_key: ***"
else
	echo_details "* secret_access_key: [EMPTY]"
fi
echo_details "* download_bucket: $download_bucket"
echo_details "* download_local_path: $download_local_path"
echo_details "* aws_region: $aws_region"
echo

validate_required_input "access_key_id" $access_key_id
validate_required_input "secret_access_key" $secret_access_key
validate_required_input "download_bucket" $download_bucket
validate_required_input "download_local_path" $download_local_path

# this expansion is required for paths with ~
#  more information: http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
eval expanded_download_local_path="${download_local_path}"

if [ ! -n "${download_bucket}" ]; then
  print_failed_message 'Input download_bucket is missing'
  exit 1
fi

if [ ! -e "${expanded_download_local_path}" ]; then
  print_failed_message "The specified local path doesn't exist at: ${expanded_download_local_path}"
  exit 1
fi

if [[ "$aws_region" != "" ]] ; then
	echo_details "AWS region (${aws_region}) specified!"
	export AWS_DEFAULT_REGION="${aws_region}"
fi

s3_url="s3://${download_bucket}"
export AWS_ACCESS_KEY_ID="${access_key_id}"
export AWS_SECRET_ACCESS_KEY="${secret_access_key}"

# do a sync -> delete no longer existing objects
#echo_info "$ aws s3 sync ${expanded_download_local_path} ${s3_url} --delete --a"
echo_info "$ aws s3 sync ${s3_url} ${expanded_download_local_path}"
aws s3 sync "${s3_url}" "${expanded_download_local_path}" 

echo_done "Success"
if [[ -n ${AWS_DEFAULT_REGION} ]] ; then
  echo_details "AWS Region: ${aws_region}"
fi
echo_details "Base URL: http://${download_bucket}.s3.amazonaws.com/"
