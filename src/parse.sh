


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/contains.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v2.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh



# fun: shelduck_apply_imports [OPTIONS] CODESCRIPT FILTER LISTENER [ARGS]
# listener: fun: listener BEFORE CMDLINE AFTER
#           res: true ADDTORESULT NEWINPUT
# res: true  REWRITTENSCRIPT
# res: false error message
shelduck_parse_commands() {

	_shelduck_parse_commands__input="$1"
	_shelduck_parse_commands__filter="$2"
	shift 2

	_shelduck_parse_commands__result=
	while [ -n "$_shelduck_parse_commands__input" ]; do
		shelduck_next_command "$_shelduck_parse_commands__input" "$_shelduck_parse_commands__filter"
		if ! bobshell_result_check; then
			break
		fi

		_shelduck_parse_commands__before="$bobshell_result_2"
		_shelduck_parse_commands__command="$bobshell_result_3"
		_shelduck_parse_commands__input="$bobshell_result_4"
		bobshell_var_append _shelduck_parse_commands__result "$_shelduck_parse_commands__before"

		# save state before recursive call
		set -- "$_shelduck_parse_commands__result" "$_shelduck_parse_commands__filter" "$@"

		# recursive call
		bobshell_shift_exec 2 "$@" "$_shelduck_parse_commands__before" "$_shelduck_parse_commands__command" "$_shelduck_parse_commands__input"
		unset _shelduck_parse_commands__before _shelduck_parse_commands__command _shelduck_parse_commands__input

		# restore state
		_shelduck_parse_commands__result="$1"
		_shelduck_parse_commands__filter="$2"
		shift 2

		# get result
		bobshell_result_assert
		_shelduck_parse_commands__input="$bobshell_result_3"
		bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_2"
	done
	unset _shelduck_parse_commands__filter

	# accumulate the rest of script after last shelduck import
	bobshell_var_append _shelduck_parse_commands__result "$_shelduck_parse_commands__input"
	unset _shelduck_parse_commands__input

	# return result
	bobshell_result_set true "$_shelduck_parse_commands__result"
	unset _shelduck_parse_commands__result
}


# fun: shelduck_next_command INPUT [ SUBCMDFILTER=* ]
# res: true BEFORE COMMAND AFTER
# res: false
shelduck_next_command() {
	if [ -z "$1" ]; then
		bobshell_result_set_1 false
		return
	fi

	_shelduck_next_command__rest="$1"
	_shelduck_next_command__filter="${2:-*}"
	shift 2

	# search for next unindented shelduck command
	_shelduck_next_command__skip=
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" 'shelduck ' 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			unset _shelduck_next_command__rest _shelduck_next_command__skip
			bobshell_result_set_1 false
			return
		fi
		_shelduck_next_command__rest="$bobshell_result_2"

		# check for indentation
		if [ -n "$bobshell_result_1" ] \
				&& ! bobshell_ends_with "$bobshell_result_1" "$bobshell_newline"; then
			# command is indentated, skip
			bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"'shelduck '
			continue
		fi

		bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"


		if [ "$_shelduck_next_command__filter" = '*' ]; then
			break
		fi

		bobshell_str_split_v2 "$_shelduck_next_command__rest" "$bobshell_newline" 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			_shelduck_next_command__subcommand="$_shelduck_next_command__rest"
		else
			_shelduck_next_command__subcommand="$bobshell_result_1"
		fi

		bobshell_str_split_v2 "$_shelduck_next_command__subcommand" ' ' 2
		if [ "$bobshell_result_size" -ge 2 ]; then
			_shelduck_next_command__subcommand="$bobshell_result_1"
		fi

		bobshell_str_match "$_shelduck_next_command__subcommand" "$_shelduck_next_command__filter"
		unset _shelduck_next_command__subcommand
		if bobshell_result_check; then
			break
		fi

		bobshell_var_append _shelduck_next_command__skip 'shelduck '
	done
	unset _shelduck_next_command__filter

	shelduck_parse_command "$_shelduck_next_command__rest"
	bobshell_result_assert _shelduck_next_command__command _shelduck_next_command__rest
	_shelduck_next_command__command="shelduck $_shelduck_next_command__command"
	bobshell_result_set_4 true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" "$_shelduck_next_command__rest"
	unset _shelduck_next_command__skip _shelduck_next_command__command _shelduck_next_command__rest

}


# fun: shelduck_parse_command INPUT
# res: true COMMAND REST
shelduck_parse_command() {
	_shelduck_parse_command__found=
	_shelduck_parse_command__input="$1"
	while [ -n "$_shelduck_parse_command__input" ]; do
		bobshell_str_split_v3 "$_shelduck_parse_command__input" "${bobshell_newline}"
		if bobshell_result_check _shelduck_parse_command__line _shelduck_parse_command__input; then
			bobshell_var_append _shelduck_parse_command__found "$_shelduck_parse_command__line$bobshell_newline"
			bobshell_str_suffix "$_shelduck_parse_command__line" '\'
			unset _shelduck_parse_command__line
			if ! bobshell_result_check; then
				break
			fi
		else
			bobshell_var_append _shelduck_parse_command__found "$_shelduck_parse_command__input"
			_shelduck_parse_command__input=
			break
		fi
	done
	bobshell_result_set true "$_shelduck_parse_command__found" "$_shelduck_parse_command__input"
	unset _shelduck_parse_command__found _shelduck_parse_command__input
}
