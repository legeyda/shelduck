

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/insert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh

shelduck import ../sub.sh
shelduck import ../done.sh
shelduck import ../../util.sh
shelduck import ./line.sh


# fun: shelduck_parse_command INPUT [ LISTENER ... ]
# res: true COMMAND REST
shelduck_parse_command_argv() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	shelduck_parse_command_line "$@" argv
	if ! bobshell_result_check _shelduck_parse_command_argv__result _shelduck_parse_command_argv__input; then
		bobshell_result_insert 2 'line expected'
		return
	fi

	while true; do
		# if ends with \ or \<newline> then continue
		bobshell_str_suffix "$_shelduck_parse_command_argv__result" "$bobshell_newline"
		if ! bobshell_result_check _shelduck_parse_command_argv__x; then
			_shelduck_parse_command_argv__x="$_shelduck_parse_command_argv__result"
		fi
		bobshell_str_suffix "$_shelduck_parse_command_argv__x" '\'
		unset _shelduck_parse_command_argv__x
		if ! bobshell_result_check; then
			break
		fi

		# assert ends with '\'
		shelduck_preserve2 _shelduck_parse_command_argv__result _shelduck_parse_command_argv__input \
				shelduck_parse_sub shelduck_parse_command_line "$_shelduck_parse_command_argv__input" "$@" argv

		if ! bobshell_result_check; then
			unset _shelduck_parse_command_argv__result _shelduck_parse_command_argv__input
			bobshell_result_insert 2 'line expected'
			return
		fi

		_shelduck_parse_command_argv__result="$_shelduck_parse_command_argv__result$bobshell_result_2"
		_shelduck_parse_command_argv__input="$bobshell_result_3"
	done

	#
	set -- "$@" argv "$_shelduck_parse_command_argv__result" "$_shelduck_parse_command_argv__input"
	unset _shelduck_parse_command_argv__result _shelduck_parse_command_argv__input
	shelduck_parse_done "$@"
}
