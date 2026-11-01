

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh


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
