

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/insert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh

shelduck import ./sub.sh
shelduck import ./line.sh
shelduck import ./done.sh
shelduck import ../util.sh


# fun: shelduck_parse_command INPUT [ LISTENER ... ]
# res: true COMMAND REST
shelduck_parse_command() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	shelduck_parse_line "$@" command
	if ! bobshell_result_check _shelduck_parse_command__result _shelduck_parse_command__input; then
		bobshell_result_insert 2 'line expected'
		return
	fi

	while true; do

		bobshell_str_split_v3 "$_shelduck_parse_command__result" '<<'
		if bobshell_result_check _shelduck_parse_command__left _shelduck_parse_command__right; then

			bobshell_str_match "$_shelduck_parse_command__right" '*[!_A-Za-z\\'"'"']*
'
			if ! bobshell_result_check; then
				set -- "$@" command "$_shelduck_parse_command__left" '<<'"$_shelduck_parse_command__right$_shelduck_parse_command__input"
				unset _shelduck_parse_command__result _shelduck_parse_command__input
				unset _shelduck_parse_command__left _shelduck_parse_command__right
				shelduck_parse_done "$@"
				return
			fi
			unset _shelduck_parse_command__left _shelduck_parse_command__right
		fi

		# todo if ends with '\' then error newline expected
		if ! bobshell_ends_with "$_shelduck_parse_command__result" '\'"$bobshell_newline"; then
			set -- "$@" command "$_shelduck_parse_command__result" "$_shelduck_parse_command__input"
			unset _shelduck_parse_command__result _shelduck_parse_command__input
			shelduck_parse_done "$@"
			return
		fi

		# assert ends with '\'
		shelduck_preserve2 _shelduck_parse_command__result _shelduck_parse_command__input \
				shelduck_parse_sub shelduck_parse_line "$_shelduck_parse_command__input" "$@" command

		if ! bobshell_result_check; then
			bobshell_result_insert 2 'line expected'
			return
		fi

		_shelduck_parse_command__result="$_shelduck_parse_command__result$bobshell_result_2"
		_shelduck_parse_command__input="$bobshell_result_3"
	done
}
