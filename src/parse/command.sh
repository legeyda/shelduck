

shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/insert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/var/append.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/prefix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh

shelduck import ./sub.sh
shelduck import ./done.sh
shelduck import ../util.sh
shelduck import ./heredoc.sh
shelduck import ./command/argv.sh


# fun: shelduck_parse_command INPUT [ LISTENER ... ]
# res: true COMMAND REST
shelduck_parse_command() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	shelduck_parse_command_argv "$@" command
	if ! bobshell_result_check _shelduck_parse_command__result _shelduck_parse_command__input; then
		bobshell_result_insert 2 'argv expected'
		return
	fi

	bobshell_str_prefix "$_shelduck_parse_command__input" '<<'
	if bobshell_result_check; then
		shelduck_preserve2 _shelduck_parse_command__result _shelduck_parse_command__input \
				shelduck_parse_sub shelduck_parse_heredoc "$_shelduck_parse_command__input" "$@" command
		bobshell_result_assert
		_shelduck_parse_command__result="$_shelduck_parse_command__result$bobshell_result_2"
		_shelduck_parse_command__input="$bobshell_result_3"
	fi


	#
	set -- "$@" command "$_shelduck_parse_command__result" "$_shelduck_parse_command__input"
	unset _shelduck_parse_command__result _shelduck_parse_command__input
	shelduck_parse_done "$@"
}
