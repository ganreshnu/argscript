#!/bin/env argscript

local argv=()
local -A args=(
	[flag]=''
	[required]='default'
	[optional]=''
)
Usage() {
	cat <<EOD
Usage: $(basename "$BASH_SOURCE") [OPTIONS] FILENAME

Options:
  -f, --flag                A flag argument.
  -r, --required STRING     A required argument.
  -o, --optional [STRING]   An optional argument.
  --help                    Show this message and exit.

An example script for the argument processor.
EOD
}

Argument() {
	if [[ "$1" ]]; then
		[[ "$3" ]] && args["$1"]="$3" || args["$1"]=true
	else
		argv+=( "$3" )
	fi
	return 0
}

Main() {
	for key in "${!args[@]}"; do
		printf "$(tput setaf 2)%s$(tput sgr0): %s\n" "$key" "${args[$key]}"
	done
	printf "%i positionals: %s\n" ${#argv[@]} "${argv[*]}"

	printf "%i arguments remaining: %s\n" $# "$*"
}
# vim: ts=4
