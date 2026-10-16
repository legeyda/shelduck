

# fun: shelduck_next_command INPUT
# res: true SKIP COMMAND REST
# res: false
shelduck_next_command() {
	if [ -z "$1" ]; then
		bobshell_result_set false
		return
	fi

	_shelduck_next_command__rest="$1"
	shift

	# search for next unindented shelduck command
	_shelduck_next_command__skip=
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" 'shelduck ' 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			unset _shelduck_next_command__rest _shelduck_next_command__skip
			bobshell_result_set false
			return
		fi
		_shelduck_next_command__rest="$bobshell_result_2"

		# check for indentation
		if [ -n "$bobshell_result_1" ] && ! bobshell_ends_with "$bobshell_result_1" "$bobshell_newline"; then
			# command is indentated, skip
			bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"'shelduck '
			continue
		fi

		bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"
		break
	done

	# trace command to multiple lines
	_shelduck_next_command__command='shelduck '
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" "${bobshell_newline}" 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			bobshell_var_append _shelduck_next_command__command "$bobshell_result_1"
			bobshell_result_set true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" ''
			break
		fi

		_shelduck_next_command__candidate="$bobshell_result_1"
		_shelduck_next_command__rest="$bobshell_result_2"

		bobshell_str_suffix "$_shelduck_next_command__candidate" '\'
		if bobshell_result_check; then
			unset _shelduck_next_command__candidate
			bobshell_var_append _shelduck_next_command__command "$bobshell_result_2"'\'"$bobshell_newline"
			continue
		else
			_shelduck_next_command__rest="$bobshell_newline$_shelduck_next_command__rest"
			bobshell_var_append _shelduck_next_command__command "$_shelduck_next_command__candidate"
			bobshell_result_set true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" "$_shelduck_next_command__rest"
			break
		fi
	done
	unset _shelduck_next_command__skip _shelduck_next_command__command _shelduck_next_command__rest
}
