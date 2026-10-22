


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/contains.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v2.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh

# fun: shelduck_quick_check INPUT [SUBCOMMAND ... ]
shelduck_quick_check() {
	_shelduck_quick_check="$1"
	while [ $# -gt 1 ]; do
		shift
		bobshell_str_contains "$_shelduck_quick_check" "shelduck $1"
		if bobshell_result_check; then
			unset _shelduck_quick_check
			bobshell_result_set_1 true
			return
		fi
	done
	unset _shelduck_quick_check
	bobshell_result_set_1 false
}


shelduck_parse_cli() {
	bobshell_result_set_2 0 false
	while [ "$#" -gt 0 ]; do
		case "$1" in
			(--)
				shift;
				bobshell_result_1=$(( bobshell_result_1 + 1 ))
				break ;;
			(--zero-indent) bobshell_result_2=true ;;
			(-*) bobshell_die "shelduck_parse_cli: unexpected parameter $1" ;;
			(*) break ;;
		esac
		shift
		bobshell_result_1=$(( bobshell_result_1 + 1 ))
	done
}

# fun: shelduck_apply_imports [OPTIONS] CODESCRIPT FILTER LISTENER [ARGS]
# listener: fun: listener BEFORE CMDLINE AFTER
#           res: true ADDTORESULT NEWINPUT
# res: true  REWRITTENSCRIPT
# res: false error message
shelduck_parse_commands() {
	shelduck_parse_cli "$@"
	shift "$bobshell_result_1"
	_shelduck_parse_commands__zero_indent="$bobshell_result_2"

	_shelduck_parse_commands__input="$1"
	_shelduck_parse_commands__filter="$2"
	shift 2

	_shelduck_parse_commands__result=
	while [ -n "$_shelduck_parse_commands__input" ]; do
		if [ true = "$_shelduck_parse_commands__zero_indent" ]; then
			shelduck_next_command --zero-indent -- "$_shelduck_parse_commands__input" "$_shelduck_parse_commands__filter"
		else
			shelduck_next_command -- "$_shelduck_parse_commands__input" "$_shelduck_parse_commands__filter"
		fi
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

	shelduck_parse_cli "$@"
	shift "$bobshell_result_1"
	_shelduck_parse_command__zero_indent="$bobshell_result_2"

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
				&& [ true = "$_shelduck_parse_command__zero_indent" ] \
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
	done
	unset _shelduck_parse_command__zero_indent _shelduck_next_command__filter


	# trace command to multiple lines
	_shelduck_next_command__command='shelduck '
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" "${bobshell_newline}" 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			bobshell_var_append _shelduck_next_command__command "$bobshell_result_1"
			bobshell_result_set_4 true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" ''
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
			bobshell_result_set_4 true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" "$_shelduck_next_command__rest"
			break
		fi
	done
	unset _shelduck_next_command__skip _shelduck_next_command__command _shelduck_next_command__rest
}
