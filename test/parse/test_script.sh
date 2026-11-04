
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
	if [ script = "$1" ] && [ command = "$2" ] && [ heredoc = "$3" ]; then
		true
	fi



	# if [ "$1-${2:-}-${3:-}" = script-command-line ]; then
	# 	shift 2
	# 	bobshell_result_set true rewrite 4 "$2"
	# fi
	if [ "$1-${2:-}-${3:-}-${4:-}" = script-command-heredoc-content ]; then
		shift 4
		heredoc_content="$1"
	elif [ "$1-${2:-}-${3:-}" = script-command-heredoc ]; then
		shift 3
		if [ "${heredoc_content:-}" = '5'"$bobshell_newline" ]; then
			bobshell_result_set true rewrite "$heredoc_content" "$2"
		fi
		unset heredoc_content
	elif [ "$1-${2:-}" = script-command ]; then
			shift 2
			if [ "$1" = 'shelduck two'"$bobshell_newline" ]; then
				bobshell_result_set true rewrite '2
' "$2"
				return
			fi

			bobshell_str_prefix "$1" 'shelduck four '
			if bobshell_result_check; then
				bobshell_result_set true rewrite 4'
'"$bobshell_result_2" "$2"
				return
			fi
			bobshell_result_set true noop
	fi
}

# test_02() {
# 	shelduck_parse_script 'shelduck four <<EOF
#
# EOF'
# 	assert_result_equals false 'correct eof expected:' 'only escaped heredocs supported'
# }
