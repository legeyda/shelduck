
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh


shelduck import ../../src/parse/script.sh



test_01() {
	x=
	shelduck_parse_script '
1
shelduck two
3
shelduck four <<\EOF
5
EOF
6' listner

	assert_result_equals true '
1
2
3
4
5
6' ''

#"$x"
}

listner() {
	# if [ "$1-${2:-}-${3:-}" = script-command-line ]; then
	# 	shift 2
	# 	bobshell_result_set true rewrite 4 "$2"
	# fi
	if [ "$1-${2:-}" = script-command ]; then
		shift 2
		if bobshell_starts_with "$1" 'shelduck two'; then
			bobshell_result_set true rewrite '2
' "$2"
		elif bobshell_starts_with "$1" 'shelduck four'; then
			bobshell_result_set true rewrite '4
' "$2"
		fi



		#bobshell_die '<'"$1"'>' '<'"$2"'>'
	elif [ "$1-${2:-}-${3:-}" = script-heredoc-content ]; then
		heredoc_content="$4"
	elif [ "$1-${2:-}" = script-heredoc ]; then
		# bobshell_result_set true rewrite 5 "$4"

		if [ "${heredoc_content:-}" = '5'"$bobshell_newline" ]; then
			bobshell_result_set true rewrite 5"$bobshell_newline" "$4"
		fi
		unset heredoc_content
	fi
	# x="$x"'<'"$(printf '<%s> ' "$@")"'> '
}
