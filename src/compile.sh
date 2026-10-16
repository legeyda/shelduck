
# fun: shelduck_compile URL
# api: private
# env: shelduck_base_url
# env: shelduck_compile_history
# txt: exported with build
shelduck_compile() {

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
		_shelduck_import__add_script="
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
		_shelduck_compile_script='

# shelduck: script '"$1"'
'"$_shelduck_compile_script"'
# shelduck: end of script '"$1"'

'

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
	shelduck_parse_commands "$_shelduck_compile_script" "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- process_imports failed

	# restore state
	unset shelduck_base_url
	if [ -n "$1" ]; then
		shelduck_base_url="$1"
	fi
	# shift

	bobshell_result_set true "$_shelduck_compile_script"
	unset _shelduck_compile_script

}



# fun: shelduck_apply_imports CODESCRIPT URL
# res: true  REWRITTENSCRIPT
# res: false error message
shelduck_parse_commands() {
	_shelduck_parse_commands__input="$1"
	shift

	# iterate over all shelduck imports in input script
	_shelduck_parse_commands__result=
	while [ -n "$_shelduck_parse_commands__input" ]; do
		bobshell_str_split_v2 "$_shelduck_parse_commands__input" 'shelduck ' 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			break
		fi
		_shelduck_parse_commands__input="$bobshell_result_2"

		# check for supported subcommands
		# todo
		# bobshell_str_math "$_shelduck_parse_commands__input" '"import "*'
		# if bobshell_result_check
		if bobshell_starts_with "$_shelduck_parse_commands__input" 'import '; then
			: # ok, continue
		elif bobshell_starts_with "$_shelduck_parse_commands__input" 'fetch '; then
			: # ok, continue
		else # unsupported command, skip
			bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"'shelduck '
			continue
		fi

		# check for indentation
		if [ -n "$bobshell_result_1" ] && ! bobshell_ends_with "$bobshell_result_1" "$bobshell_newline"; then
			# command is indentated, skip
			bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"'shelduck '
			continue
		fi

		bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"
		_shelduck_parse_commands__command=
		while true; do
			bobshell_str_split_v2 "$_shelduck_parse_commands__input" "${bobshell_newline}" 2
			if [ "$bobshell_result_size" -lt 2 ]; then
				bobshell_var_append _shelduck_parse_commands__command "$bobshell_result_1"
				_shelduck_parse_commands__input=
				break
			fi

			_shelduck_parse_commands__candidate="$bobshell_result_1"
			_shelduck_parse_commands__input="$bobshell_result_2"

			bobshell_str_suffix "$_shelduck_parse_commands__candidate" '\'
			if bobshell_result_check; then
				bobshell_var_append _shelduck_parse_commands__command "$bobshell_result_2 "
			else
				_shelduck_parse_commands__input="$bobshell_newline$_shelduck_parse_commands__input"
				bobshell_var_append _shelduck_parse_commands__command "$_shelduck_parse_commands__candidate"
				break
			fi
			unset _shelduck_parse_commands__candidate

		done
		if [ -z "$_shelduck_parse_commands__command" ]; then
			bobshell_die empty command
		fi

		# save state before recursive call
		set -- "$_shelduck_parse_commands__result" "$_shelduck_parse_commands__input" "$_shelduck_parse_commands__command" "$@"
		unset    _shelduck_parse_commands__result    _shelduck_parse_commands__input

		shelduck_process_command $_shelduck_parse_commands__command

		# restore state after recursive all
		_shelduck_parse_commands__result="$1"
		_shelduck_parse_commands__input="$2"
		_shelduck_parse_commands__command="$3"
		shift 3

		# accumulate result of recursive call
		bobshell_result_assert -- error processing "$_shelduck_parse_commands__command"
		bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_2"

		unset _shelduck_parse_commands__command
	done

	# accumulate the rest of script after last shelcuk import
	bobshell_var_append _shelduck_parse_commands__result "$_shelduck_parse_commands__input"
	unset _shelduck_parse_commands__input

	# return result
	bobshell_result_set true "$_shelduck_parse_commands__result"
	unset _shelduck_parse_commands__result
}




shelduck_process_command() {
	case "$1" in
		(import)
			shift
			shelduck_compile "$@"
			;;

		(fetch)
			shift
			shelduck_fetch "$@"
			# todo print
			;;

		(*)
			bobshell_result_set false unsupported command "$1"
			;;
	esac
}



shelduck_compile_command_listener() {

	# shelduck preprocess replace %%_ com_legeyda_bobshell_

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'import '
	if bobshell_result_check _shelduck_parse_commands__command; then
		shelduck_compile "$_shelduck_parse_commands__command"
		bobshell_result_assert
		bobshell_result_set true apply "$bobshell_result_2"
	fi

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'fetch '
	if bobshell_result_check _shelduck_parse_commands__command; then
		shelduck_fetch "$_shelduck_parse_commands__command"
		break # todo
	fi

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'transform '
	if bobshell_result_check _shelduck_parse_commands__command; then
		bobshell_die transform unsupported in compile mode
	fi


	bobshel_result_set true skip
	_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
	unset _shelduck_parse_commands__command
	break


}

shelduck_process_compile_commands() {
	_shelduck_parse_commands__input="$1"
	shift
	_shelduck_parse_commands__result=
	while true; do
		shelduck_next_command "$_shelduck_parse_commands__input"
		if bobshell_result_check; then
			_shelduck_parse_commands__result="$_shelduck_parse_commands__result$bobshell_result_2"
			_shelduck_parse_commands__command="$bobshell_result_3"
			_shelduck_parse_commands__input="$bobshell_result_4"

			bobshell_str_prefix "$_shelduck_parse_commands__command" 'shelduck '
			bobshell_result_assert _shelduck_parse_commands__command -- command parse failed

			bobshell_str_replace "$_shelduck_parse_commands__command" '\'"$bobshell_newline" ' '
			bobshell_result_assert - _shelduck_parse_commands__command

			"$@" "$_shelduck_parse_commands__result" "$_shelduck_parse_commands__command" "$_shelduck_parse_commands__input"

			bobshell_result_assert  -- parse failed
			if [ apply = "$bobshell_result_2" ]; then
				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$bobshell_result_3"
			elif [ skip = "$bobshell_result_2" ]; then
				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
			else
				bobshell_die 'shelduck_parse_commands: unsupported result from listener ('"$bobshell_result_2"')'
			fi


			while true; do
				bobshell_str_prefix "$_shelduck_parse_commands__command" 'import '
				if bobshell_result_check _shelduck_parse_commands__command; then
					shelduck_compile "$_shelduck_parse_commands__command"
				fi

				bobshell_str_prefix "$_shelduck_parse_commands__command" 'fetch '
				if bobshell_result_check _shelduck_parse_commands__command; then
					shelduck_fetch "$_shelduck_parse_commands__command"
					break # todo
				fi

				bobshell_str_prefix "$_shelduck_parse_commands__command" 'transform '
				if bobshell_result_check _shelduck_parse_commands__command; then
					bobshell_die transform unsupported in compile mode
				fi

				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
				unset _shelduck_parse_commands__command
				break
			done
		else
			_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__input"
			break
		fi
	done

	unset _shelduck_parse_commands__input
	bobshell_result_set true "$_shelduck_parse_commands__result"
	unset _shelduck_parse_commands__result
}
