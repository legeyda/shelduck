



shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/match.sh

shelduck import ./done.sh
shelduck import ./sub.sh
shelduck import ./unstruct.sh
shelduck import ./command.sh
shelduck import ./heredoc.sh
shelduck import ../util.sh



shelduck transform replace scr shelduck_parse_script


# fun: shelduck_parse_script INPUT [ LISTENER ... ]
# listener: fun: listener FOUND
#           res: true ADDTORESULT NEWINPUT
# res: true  REWRITTENSCRIPT
# res: false error message
scr() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	_scr__result=
	_scr__input="$1"

	while [ -n "$_scr__input" ]; do
		case "$_scr__input" in
			('')
				break
				;;


			('shelduck '*)
				shelduck_preserve2 _scr__result _scr__input \
						shelduck_parse_sub shelduck_parse_command "$_scr__input" "$@" sc''ript
				if ! bobshell_result_check; then
					break
				fi

				_scr__result="$_scr__result$bobshell_result_2"
				_scr__input="$bobshell_result_3"

				shelduck_preserve2 _scr__result _scr__input \
						shelduck_parse_sub shelduck_parse_heredoc "$_scr__input" "$@" sc''ript
				if bobshell_result_check; then
					_scr__result="$_scr__result$bobshell_result_2"
					_scr__input="$bobshell_result_3"
				fi


				;;

			(*)
				shelduck_preserve2 _scr__result _scr__input \
						shelduck_parse_sub shelduck_parse_unstruct "$_scr__input" "$@" sc''ript
				if ! bobshell_result_check; then
					break
				fi

				_scr__result="$_scr__result$bobshell_result_2"
				_scr__input="$bobshell_result_3"



				;;


		esac
	done

	set -- "$@" sc''ript "$_scr__result" "$_scr__input"
	unset _scr__result _scr__input
	shelduck_parse_done "$@"
}
