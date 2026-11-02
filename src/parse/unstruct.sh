
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/match.sh

shelduck import ./done.sh


# fun: shelduck_parse_unstruct INPUT
# res: true FOUND REST
#      false
shelduck_parse_unstruct() {
	if [ -z "$1" ]; then
		bobshell_result_set_1 false
		return
	fi

	bobshell_str_split_v3 "$1" "$bobshell_newline"'shelduck '
	if bobshell_result_check; then
		set -- "$@" unstruct
		bobshell_result_set true "$bobshell_result_2$bobshell_newline" 'shelduck '"$bobshell_result_3"
	else
		bobshell_result_set true "$1" ''
	fi

	shelduck_parse_done
}
