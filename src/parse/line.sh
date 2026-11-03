
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh

shelduck import ./done.sh

# fun: shelduck_parse_line INPUT [ LISTENER ... ]
shelduck_parse_line() {

	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	if [ -z "$1" ]; then
		bobshell_result_set_1 false
		return
	fi
	bobshell_str_split_v3 "$1" "$bobshell_newline"
	if bobshell_result_check; then
		shelduck_parse_done "$@" line "$bobshell_result_2$bobshell_newline" "$bobshell_result_3"
	else
		shelduck_parse_done "$@" line "$1" ''
	fi
}
