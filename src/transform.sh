

# fun: shelduck_transform SCRIPTTEXT [ ABSURL ]
# txt: make transformation of module src regardless of context, the result of transform can be cached
shelduck_transform() {
	_shelduck_transform__script="$1"
	shift

	# maybe write comment at the beginning of result
	if bobshell_starts_with "${1:-}" file:// https:// http:// stdin:; then
		if bobshell_starts_with "$_shelduck_transform__script" "$bobshell_newline"; then
			_shelduck_transform__script='

# shelduck: script '"$1"'
'"$_shelduck_transform__script"'
# shelduck: end of script '"$1"'

'
		fi
	fi

	shelduck_preprocess "$_shelduck_transform__script"
	bobshell_result_assert _shelduck_transform__script -- shelduck_transform: shelduck_preprocess failed

	set -- "$_shelduck_transform__script" "$@"
	unset _shelduck_transform__script

	bobshell_event_fire shelduck_transform_event "$@"

	bobshell_result_set true "$1"
}


# fun: shelduck_preprocess INPUT
# res: true RESULTTEXT
# res: false error message
shelduck_preprocess() {
	if ! bobshell_contains "$1" 'shelduck preprocess '; then
		if ! bobshell_contains "$1" 'shelduck preprocess replace ' && ! bobshell_contains "$1" 'shelduck preprocess sed '; then
			bobshell_result_set_2 true "$1"
			return
		fi
	fi

	_shelduck_preprocess__input="$1"
	shift
	_shelduck_preprocess__result=
	while [ -n "$_shelduck_preprocess__input" ]; do
		shelduck_next_command "$_shelduck_preprocess__input"
		if ! bobshell_result_check; then
			_shelduck_preprocess__result="$_shelduck_preprocess__result$_shelduck_preprocess__input"
			_shelduck_preprocess__input=
			break
		fi

		_shelduck_preprocess__result="$_shelduck_preprocess__result$bobshell_result_2"
		_shelduck_preprocess__command="$bobshell_result_3"
		_shelduck_preprocess__input="$bobshell_result_4"

		bobshell_str_prefix "$_shelduck_preprocess__command" 'shelduck preprocess '
		if ! bobshell_result_check _shelduck_preprocess__command; then
			# skip
			_shelduck_preprocess__result="$_shelduck_preprocess__result$_shelduck_preprocess__command"
			unset _shelduck_preprocess__command
			continue
		fi

		eval 'shelduck_preprocess_item "$_shelduck_preprocess__input" '"$_shelduck_preprocess__command" # todo fix shell injection
		bobshell_result_assert _shelduck_preprocess__input -- preprocess failed
		unset _shelduck_preprocess__command
	done

	unset _shelduck_preprocess__input
	bobshell_result_set true "$_shelduck_preprocess__result"
	unset _shelduck_preprocess__result
}

shelduck_preprocess_item() {
	if [ replace = "$2" ]; then
		if [ $# -lt 4 ]; then
			bobshell_result_set_2 false '2 arguments expected
			return'
		fi
		bobshell_str_replace "$1" "$3" "$4"
	elif [ sed = "$2" ]; then
		if ! _shelduck_preprocess_item__result=$(printf %s "$1" | bobshell_shift_exec 1 "$@"); then
			unset _shelduck_preprocess_item__result
			_shelduck_preprocess__msg='error getting error message'
			_shelduck_preprocess__msg=$(printf %s "$_shelduck_preprocess__input" | "$@" 1>/dev/null 2>&1) || true
			bobshell_result_set_2 false "sed invocation error: $_shelduck_preprocess__msg"
			unset _shelduck_preprocess__msg
			return
		fi
		bobshell_result_set_2 true "$_shelduck_preprocess_item__result"
		unset _shelduck_preprocess_item__result
	else
		bobshell_result_set false shelduck preprocess: command "$1" not supported
		return
	fi
}
