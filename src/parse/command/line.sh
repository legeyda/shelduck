

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/match.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh

shelduck import ../sub.sh
shelduck import ../done.sh

# fun: shelduck_parse_line INPUT [ LISTENER ... ]
shelduck_parse_command_line() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	if [ -z "$1" ]; then
		bobshell_result_set_1 false
		return
	fi

	# находим строку
	bobshell_str_split_v3 "$1" "$bobshell_newline"
	if bobshell_result_check; then
		_shelduck_parse_command_line__result="$bobshell_result_2$bobshell_newline"
		_shelduck_parse_command_line__input="$bobshell_result_3"
	else
		_shelduck_parse_command_line__result="$1"
		_shelduck_parse_command_line__input=''
	fi


	# если есть << отрезаем
	bobshell_str_split_v3 "$_shelduck_parse_command_line__result" '<<'
	if bobshell_result_check _shelduck_parse_command__left _shelduck_parse_command__right; then

		bobshell_str_suffix "$_shelduck_parse_command__right" "$bobshell_newline"
		if ! bobshell_result_check _shelduck_parse_command__right2; then
			_shelduck_parse_command__right2=$_shelduck_parse_command__right
		fi

		bobshell_str_match "$_shelduck_parse_command__right2" '*[!_A-Za-z\\'"'"']*'
		unset _shelduck_parse_command__right2
		if bobshell_result_check; then
			unset _shelduck_parse_command__left _shelduck_parse_command__right
		else
			_shelduck_parse_command_line__result=$_shelduck_parse_command__left
			_shelduck_parse_command_line__input='<<'"$_shelduck_parse_command__right$_shelduck_parse_command_line__input"
			unset _shelduck_parse_command__left _shelduck_parse_command__right
		fi
	fi



	# возращаем результат
	set -- "$@" line "$_shelduck_parse_command_line__result" "$_shelduck_parse_command_line__input"
	unset _shelduck_parse_command_line__result _shelduck_parse_command_line__input
	shelduck_parse_done "$@"
}
