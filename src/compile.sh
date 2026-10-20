
# fun: shelduck_compile URL
# api: private
# env: shelduck_base_url
# env: shelduck_compile_history
# txt: exported with build
shelduck_compile() {

	bobshell_log_debug shelduck_compile: "$@"

	shelduck_parse_import_cli "$@"
	shelduck_fix_url "$shelduck_import_url"
	_shelduck_compile_url="$bobshell_result_1"
	unset shelduck_import_url

	_shelduck_compile_aliases="$shelduck_import_aliases"
	unset shelduck_import_aliases

	# # todo is _shelduck_compile_initial_base_url needed?

	# load script
	shelduck_prepare "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- shelduck_compile: prepare failed

	shelduck_event_url "$_shelduck_compile_url" "$_shelduck_compile_script"

	shelduck_print_addition  "$_shelduck_compile_script" "$_shelduck_compile_url" "$_shelduck_compile_aliases"
	bobshell_result_assert _shelduck_compile_add_script -- print addition failed

	if [ -n "$_shelduck_compile_add_script" ]; then
		_shelduck_compile_add_script="
# additions for $_shelduck_compile_url ($_shelduck_compile_aliases)
$_shelduck_compile_add_script
# end of additions for $_shelduck_compile_url

"
fi


	if bobshell_contains "$_shelduck_compile_history" "[$_shelduck_compile_url]"; then
		_shelduck_compile_script="
# skip script $_shelduck_compile_url (already compiled)
$_shelduck_compile_add_script"
	else
		_shelduck_compile_history="$_shelduck_compile_history [$_shelduck_compile_url]"

		if bobshell_locator_is_remote "$_shelduck_compile_url" || bobshell_locator_is_file "$_shelduck_compile_url"; then
		_shelduck_compile_script='

# shelduck: script '"$1"'
'"$_shelduck_compile_script"'
# shelduck: end of script '"$1"'

'
		fi
		_shelduck_compile_script="$_shelduck_compile_script$_shelduck_compile_add_script"
	fi
	unset _shelduck_compile_add_script

	if [ -z "$_shelduck_compile_script" ]; then
		bobshell_result_set true "$_shelduck_compile_script"
		return
	fi

	# save state before recursive call
	set -- "$shelduck_base_url" "$@"

	# recursive calls
	shelduck_update_base_url "$_shelduck_compile_url"
	shelduck_do_compile "$_shelduck_compile_script"
	bobshell_result_assert _shelduck_compile_script -- process_imports failed

	# restore state
	unset shelduck_base_url
	if [ -n "$1" ]; then
		shelduck_base_url="$1"
	fi

	shift
	bobshell_log_debug shelduck_compile: result for "$*": "$_shelduck_compile_script"

	bobshell_result_set true "$_shelduck_compile_script"
	unset _shelduck_compile_script


}

shelduck_do_compile() {
	# todo assert no shelduck transform commands
	shelduck_parse_commands --zero-indent -- "$1" "'import '*|'fetch '*|'then '*" shelduck_compile_command
}

# fun: shelduck_compile_command INPUT "schelduck" ARGS
# implements: shelduck_parse_commands listener
# res:
shelduck_compile_command() {
	_shelduck_compile_command__input="$1"
	shift

	if [ "$1" != shelduck ]; then
		bobshell_result_set false unsupported command "$1"
		return
	fi
	shift

	case "$1" in
		(import|fetch)
			_shelduck_prepare_listener__subcmd="$1"
			shift
			set -- shelduck_compile_"$_shelduck_prepare_listener__subcmd" "$_shelduck_compile_command__input" "$@"
			unset _shelduck_compile_command__input _shelduck_prepare_listener__subcmd
			"$@"
		;;

		(*)
			bobshell_result_set_2 false "shelduck_compile_listener: unsupported subcommand $1"
			unset _shelduck_compile_command__input

		;;
	esac
}
# fun: shelduck_compile_import INPUT [IMPORTARGS ...]
shelduck_compile_import() {
	_shelduck_compile_import__input="$1"
	shift

	bobshell_log_debug shelduck_compile_import: url is "$@"

	set -- "$_shelduck_compile_import__input" shelduck_compile "$@"
	unset _shelduck_compile_import__input

	bobshell_shift_exec 1 "$@"
	bobshell_result_assert _shelduck_compile_import__compile_result

	bobshell_result_set_3 true "$_shelduck_compile_import__compile_result" "$1"
	unset _shelduck_compile_import__compile_result

}

# fun: shelduck_compile_fetch INPUT ABSURL
shelduck_compile_fetch() {
	_shelduck_compile_fetch__input="$1"
	shift

	bobshell_log_trace "shelduck_compile_fetch: $*"
	if [ $# != 1 ]; then
		bobshell_log_error          'shelduck_compile_fetch: exactly one argument expected'
		bobshell_result_set_2 false 'shelduck_compile_fetch: exactly one argument expected'
		return
	fi

	shelduck_fix_url "$1" # todo shelduck_fix_url does not return boolean as first result
	shelduck_do_fetch "$bobshell_result_1"
	if ! bobshell_result_check _shelduck_compile_fetch__result; then
		bobshell_log_error "shelduck_compile_fetch: fetch failed"
		return
	fi

	# todo? bobshell_str_quote "$_shelduck_compile_fetch__result"
	bobshell_str_match "$_shelduck_compile_fetch__result" "*'${bobshell_newline}EOF_shelduck_compile_fetch'*"
	if bobshell_result_check; then
		bobshell_log_error          "shelduck_compile_fetch: fetch result contains eof-string EOF_shelduck_compile_fetch"
		bobshell_result_set_2 false "shelduck_compile_fetch: fetch result contains eof-string EOF_shelduck_compile_fetch"
		return
	fi

	_shelduck_compile_fetch__result='
bobshell_result_size=2
bobshell_result_1=true
bobshell_result_2=$(cat <<\EOF_shelduck_compile_fetch
'"$_shelduck_compile_fetch__result"'
EOF_shelduck_compile_fetch
)
'

	bobshell_result_set_3 true "$_shelduck_compile_fetch__result" "$_shelduck_compile_fetch__input"
	unset _shelduck_compile_fetch__result _shelduck_compile_fetch__input
}
