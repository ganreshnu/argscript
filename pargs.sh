#
# need documentation here
#
# shellcheck shell=bash
pargs() {
	local __pargs_usage__=$1; shift
	local __pargs_argument__=$1; shift
	local -n __pargs_consumed__=$1; shift
	local __pargs_argc__=$#
	local __pargs_args__
	__pargs_args__=$($__pargs_usage__ | awk -F '  ' '/^  -/ { print $2 }')

	error() {
		>&2 printf "$(tput setaf 1)error:$(tput sgr0) %s\n" "$*"
	}

	__pargs_consumed__=0
	while [[ $# -gt 0 ]]; do
		local __pargs_code__=0
		case "$1" in
			-- )
				shift
				break
				;;
			-?* )
				# short arguments
				if [[ "$1" != --?* ]]; then
					# split into character array
					local -a shortargs
					mapfile -t shortargs <<< "$(fold -w 1 <<< "${1:1}")"
					# multiple args packed into one
					if [[ ${#shortargs[@]} -gt 1 ]]; then
						shift
						# reset the current argv
						set -- "${shortargs[@]/#/-}" "$@"
						continue
					fi
					unset shortargs
				fi

				# handle equals type argument
				if [[ "$1" == --*=* ]]; then
					local name="${1%%=*}"
					local value="${1##*=}"
					shift
					# reset the current argv
					if [[ "$value" ]]; then
						set -- "$name" "$value" "$@"
					else
						set -- "$name" "$@"
					fi
					unset name value
				fi

				# get argument from help
				local __pargs_argstr__
				__pargs_argstr__=$(awk -F ', ' "/^$1| $1/ { if (NF > 1) { print \$2 } else { print \$1 } }" <<< "$__pargs_args__")
				# exit if this is an unknown argument
				if [[ ! "$__pargs_argstr__" ]]; then
					error "unknown argument $1"
					$__pargs_usage__
					return 1
				fi
				# shift off this argument name
				shift
				# read the name and type from help
				local name type
				read -r name type <<< "$__pargs_argstr__"
				# check for a value
				if [[ "$type" ]]; then
					# assign the value
					if [[ $# -gt 0 && "$1" != -?* ]]; then
						$__pargs_argument__ "${name#--}" "$type" "$1" || __pargs_code__=$?
						shift
						[[ $__pargs_code__ -eq 0 ]] && continue

						# code 255 is the same as --
						[[ $__pargs_code__ -eq 255 ]] && break

						# argument function returned error status
						$__pargs_usage__
						return $__pargs_code__
					fi

					# no value passed, check for requirement
					if [[ "${type::1}" != '[' ]]; then
						error "$name requires an argument"
						$__pargs_usage__
						return 1
					fi
				fi

				# exit to help
				if [[ "$name" == '--help' ]]; then
					$__pargs_usage__
					# code 255 means exit without error
					return 255
				fi

				# set as flag
				$__pargs_argument__ "${name#--}" "$type" '' || __pargs_code__=$?
				# code 255 is equivalent to --
				[[ $__pargs_code__ -eq 255 ]] && break
				if [[ $__pargs_code__ -ne 0 ]]; then
					# argument function returned error code
					$__pargs_usage__
					return $__pargs_code__
				fi
				;;
			* )
				# positional argument
				$__pargs_argument__ '' '' "$1" || __pargs_code__=$?
				shift
				# code 255 returned by the argument function
				# is equivalent to --
				[[ $__pargs_code__ -eq 255 ]] && break
				if [[ $__pargs_code__ -ne 0 ]]; then
					# argument function returned an error code
					$__pargs_usage__
					return $__pargs_code__
				fi
				;;
		esac
	done
	__pargs_consumed__=$(( __pargs_argc__ - $# ))
}
# vim: ts=4
