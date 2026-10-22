


shelduck import ./parse.sh


# fun: shelduck_prepare ABSURL
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
	shelduck_parse_commands --zero-indent -- "$1" transform shelduck_prepare_listener
}

# fun: shelduck_compile_command BEFORE COMMAND INPUT
# implements: shelduck_parse_commands listener
# res:
shelduck_prepare_listener() {
	shift # before ignored
	_shelduck_prepare_listener__input="$2"

	shelduck_split_args "$1"
	bobshell_result_assert
	eval 'set -- '"$bobshell_result_2"

	if [ "$1" != shelduck ]; then
		bobshell_result_set false shelduck_prepare_listener: unsupported command "$1"
		return
	fi
	shift

	case "$1" in
		(transform)
			_shelduck_prepare_listener__subcmd="$1"
			shift
			set -- shelduck_prepare_"$_shelduck_prepare_listener__subcmd" "$_shelduck_prepare_listener__input" "$@"
			unset _shelduck_prepare_listener__input _shelduck_prepare_listener__subcmd
			"$@"
		;;

		(*)
			bobshell_result_set_2 false "shelduck_prepare_listener: unsupported subcommand $1"
			unset _shelduck_prepare_listener__input

		;;
	esac

}


# fun: shelduck_prepare_transform INPUT [ TRANSFORMARGS ]
shelduck_prepare_transform() {
	if [ replace = "$2" ]; then
		if [ $# -lt 4 ]; then
			bobshell_result_set_2 false '2 arguments expected'
			return
		fi
		bobshell_str_replace "$1" "$3" "$4"
		bobshell_result_set_3 true '' "$bobshell_result_2"
	elif [ sed = "$2" ]; then
		if ! _shelduck_transform_item__result=$(printf %s "$1" | bobshell_shift_exec 1 "$@"); then
			unset _shelduck_transform_item__result
			_shelduck_prepare_transform__msg='error getting error message'
			_shelduck_prepare_transform__msg=$(printf %s "$_shelduck_prepare_transform__input" | "$@" 1>/dev/null 2>&1) || true
			bobshell_result_set_2 false "sed invocation error: $_shelduck_prepare_transform__msg"
			unset _shelduck_prepare_transform__msg
			return
		fi
		bobshell_result_set_3 true '' "$_shelduck_transform_item__result"
		unset _shelduck_transform_item__result
	else
		bobshell_result_set false shelduck transform: command "$1" not supported
		return
	fi
}
