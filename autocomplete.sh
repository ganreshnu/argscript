__argscript_autocomplete__() {
		local completions
		completions="$(Usage |sed -e '/^  -/!d' \
			-e 's/^  \(-[[:alnum:]]\)\(, \(--[[:alnum:]-]\+\)\)\?\( \[\?\([[:upper:]]\+\)\)\?.*/\1=\5\n\3=\5/' \
			-e 's/^  \(--[[:alnum:]-]\+\)\( \[\?\([[:upper:]]\+\)\)\?.*/\1=\3/')"

		declare -A completion
		for c in $completions; do
			local key="${c%=*}"
			[[ "$key" ]] && completion[$key]="${c#*=}"
		done
		completions="${!completion[@]}"

		[[ $# -lt 3 ]] && local prev="$1" || prev="$3"
		[[ $# -lt 2 ]] && local cur="" || cur="$2"

		local type=""
		[[ ${completion[$prev]+_} ]] && type=${completion[$prev]}

		case "$type" in
		FILENAME )
			COMPREPLY=( "$(compgen -f -- "$cur")" )
			compopt -o filenames
			;;
		DIRECTORY )
			COMPREPLY=( "$(compgen -d -- "$cur")" )
			compopt -o filenames
			;;
		[A-Z]* )
			;;
		* )
			COMPREPLY=( "$(compgen -W "$completions" -- "$cur")" )
			;;
		esac
}

#complete -o noquote -o bashdefault -o default \
#	-F __argscript_autocomplete__ "$(basename "${BASH_SOURCE[0]}")"
# vim: ts=4
