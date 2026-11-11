

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/shiftexec.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/insert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/isset.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/match.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/replace.sh

shelduck import ./parse/script.sh
shelduck import ./prepare/transform.sh

# fun: shelduck_prepare ABSURL
# res: true SCRIPT
shelduck_prepare() {
	if bobshell_locator_is_remote "$1"; then
		shelduck_cache_get prepare "$1"
		if bobshell_result_check; then
			return
		fi
		_shelduck_prepare__cached=true
	elif bobshell_locator_is_file "$1" _shelduck_prepare__file; then
		shelduck_cache_fget prepare "$_shelduck_prepare__file"
		unset _shelduck_prepare__file
		if bobshell_result_check; then
			return
		fi
		_shelduck_prepare__cached=true
	else
		_shelduck_prepare__cached=false
	fi

	shelduck_do_fetch "$1"
	bobshell_result_assert -- shelduck_prepare: fetch failed

	shelduck_do_prepare "$bobshell_result_2"

	if bobshell_result_check _shelduck_prepare__result; then
		if shelduck_str_equals cached "$_shelduck_prepare__cached"; then
			shelduck_cache_put prepare "$1" "$_shelduck_prepare__result"
		fi
		bobshell_result_set_2 true "$_shelduck_prepare__result"
		unset _shelduck_prepare__result
	fi
	unset _shelduck_prepare__cached
}



# fun: shelduck_phase1 INPUT
# res: true RESULT
#      false
shelduck_do_prepare() {
	if bobshell_str_match "$1" '*shelduck transform *'; then
		shelduck_parse_script "$1" shelduck_prepare_listener
	else
		bobshell_result_set true "$1"
	fi
}

shelduck_prepare_listener() {
	if [ $# -ge 4 ] && [ "$1" = script ] && [ "$2" = command ]; then
		if   [ $# -eq 5 ] && [ "$3" = argv ]; then
			_shelduck_prepare_listener__argv="$4"
		elif [ $# -eq 6 ] && [ "$3" = heredoc ] && [ "$4" = content ]; then
			_shelduck_prepare_listener__stdin="$5"
		elif [ $# -eq 4 ]; then
			shift 2
			case "$1" in
				('shelduck transform '*)
					if bobshell_isset _shelduck_prepare_listener__stdin; then
						bobshell_die 'shelduck transform: heredoc not supported in prepare phase'
					fi
					shelduck_prepare_command "$_shelduck_prepare_listener__argv" "$2"
					unset _shelduck_prepare_listener__argv
					bobshell_result_assert
					bobshell_result_set true rewrite '' "$bobshell_result_2"
					return
					;;
				(*)
					bobshell_result_set_2 true cancel # false 'only transform supported in this phase'
					;;
			esac
			unset _shelduck_prepare_listener__stdin _shelduck_prepare_listener__argv
		fi
	else
		unset _shelduck_prepare_listener__argv _shelduck_prepare_listener__stdin
		bobshell_result_set true noop
	fi
}


# fun: shelduck_compile_command COMMAND INPUT
# implements: shelduck_parse_commands listener
# res: true AFTER
shelduck_prepare_command() {
	_shelduck_prepare_command__after="$2"
	unset _shelduck_prepare_command__stdin
	if [ $# -ge 3 ]; then
		_shelduck_prepare_command__stdin="$3"
	fi

	shelduck_split_args "$1"
	bobshell_result_assert
	eval 'set -- '"$bobshell_result_2"

	if [ "$1" != shelduck ]; then
		bobshell_result_set false shelduck_prepare_command: unsupported command "$1"
		return
	fi
	shift

	case "$1" in
		(transform)
			_shelduck_prepare_command__subcmd="$1"
			shift
			set -- shelduck_prepare_"$_shelduck_prepare_command__subcmd" "$_shelduck_prepare_command__after" "$@"
			unset _shelduck_prepare_command__after _shelduck_prepare_command__subcmd
			"$@"
		;;

		(*)
			bobshell_result_set_2 false "shelduck_prepare_command: unsupported subcommand $1"
			unset _shelduck_prepare_command__after

		;;
	esac

}
