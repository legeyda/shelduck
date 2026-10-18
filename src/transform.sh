


# fun: shelduck_transform INPUT
# res: true RESULTTEXT
# res: false error message
shelduck_transform() {
	shelduck_quick_check "$1" 'transform replace' 'transform sed'
	if ! bobshell_result_check; then
		bobshell_result_set_2 true "$1"
		return
	fi

	_shelduck_transform__input="$1"
	shift
	_shelduck_transform__result=
	while [ -n "$_shelduck_transform__input" ]; do
		shelduck_next_command "$_shelduck_transform__input"
		if ! bobshell_result_check; then
			_shelduck_transform__result="$_shelduck_transform__result$_shelduck_transform__input"
			_shelduck_transform__input=
			break
		fi

		_shelduck_transform__result="$_shelduck_transform__result$bobshell_result_2"
		_shelduck_transform__command="$bobshell_result_3"
		_shelduck_transform__input="$bobshell_result_4"

		bobshell_str_prefix "$_shelduck_transform__command" 'shelduck transform '
		if ! bobshell_result_check _shelduck_transform__command; then
			# skip
			_shelduck_transform__result="$_shelduck_transform__result$_shelduck_transform__command"
			unset _shelduck_transform__command
			continue
		fi

		eval 'shelduck_transform_item "$_shelduck_transform__input" '"$_shelduck_transform__command" # todo fix shell injection
		bobshell_result_assert _shelduck_transform__input -- transform failed
		unset _shelduck_transform__command
	done

	unset _shelduck_transform__input
	bobshell_result_set true "$_shelduck_transform__result"
	unset _shelduck_transform__result
}

shelduck_transform_item() {
	if [ replace = "$2" ]; then
		if [ $# -lt 4 ]; then
			bobshell_result_set_2 false '2 arguments expected
			return'
		fi
		bobshell_str_replace "$1" "$3" "$4"
	elif [ sed = "$2" ]; then
		if ! _shelduck_transform_item__result=$(printf %s "$1" | bobshell_shift_exec 1 "$@"); then
			unset _shelduck_transform_item__result
			_shelduck_transform__msg='error getting error message'
			_shelduck_transform__msg=$(printf %s "$_shelduck_transform__input" | "$@" 1>/dev/null 2>&1) || true
			bobshell_result_set_2 false "sed invocation error: $_shelduck_transform__msg"
			unset _shelduck_transform__msg
			return
		fi
		bobshell_result_set_2 true "$_shelduck_transform_item__result"
		unset _shelduck_transform_item__result
	else
		bobshell_result_set false shelduck transform: command "$1" not supported
		return
	fi
}
