#!/bin/bash

#
# something is running the script
#
set -euo pipefail

Main() {
	# import the pargs function
	. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/pargs.sh"

	error() {
		# unreachable commands here??
		# shellcheck disable=SC2317
		printf "$(tput setaf 1)error:$(tput sgr0) %s\n" "$*"
	}

	local -A __argscript_args__=(
		[template]=''
		[autocomplete]=''
	)

	Usage() {
		cat <<EOD
Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS] FILENAME

Options:
  -a, --autocomplete       Generate autocomplete and exit.
  --help                   Show this message and exit.

Execute a script template file.

A template file at it's topmost level must have the following functions:

Usage:    A function that shows usage information with each option on it's own
          line preceded by two spaces.
Argument: A callback function the accepts an argument name, type and value.
Main:     The primary script function.
EOD
	}

	Argument() {
		if [[ "$1" ]]; then
			# __argscript_args__ is in fact used...
			# shellcheck disable=SC2034
			[[ "$3" ]] && __argscript_args__["$1"]="$3" || __argscript_args__["$1"]=true
		else
			__argscript_args__[template]="$3"
			# special code 255 means to quit parsing without error
			return 255
		fi
	}

	#
	# parse the arguments
	#
	local eaten=0
	if pargs Usage Argument eaten "$@"; then
		shift $eaten
	else
		local code=$?
		# code 255 means exit without error
		[[ $code -eq 255 ]] && return 0 || return $code
	fi
	unset eaten

	# check for passed filename
	if [[ ! -r "${__argscript_args__[template]}" ]]; then
		error 'FILENAME is required, must exist and be readable.'
		Usage; return 1
	fi

	# clean the environment
	unset -f Usage Argument

	#
	# include the template
	#

	# linter can't follow this source
	# shellcheck disable=SC1090
	. "${__argscript_args__[template]}"

	if [[ "${__argscript_args__[autocomplete]}" ]]; then
		complete -o noquote -o bashdefault -o default \
			-F __argscript_autocomplete__ "$(basename "${__argscript_args__[template]}")"

		return 0
	fi

	#
	# parse the arguments
	#
	local eaten=0
	if pargs Usage Argument eaten "$@"; then
		shift $eaten
	else
		local code=$?
		# special code 255 means exit without error
		[[ $code -eq 255 ]] && return 0 || return $code
	fi
	unset eaten __argscript_args__
	unset -f error pargs

	Main "$@"
}
Main "$@"

# vim: ts=4
