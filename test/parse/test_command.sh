
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../src/parse/command.sh

test_1() {
	shelduck_parse_command hello
	assert_result_equals true hello ''
}

test_2() {
	shelduck_parse_command 'hello
hi'
	assert_result_equals true 'hello
' hi
}

test_3() {
	shelduck_parse_command 'hello \
hi
bye'
	assert_result_equals true 'hello \
hi
' bye
}

test_4() {
	unset res_argv res_stdin
	shelduck_parse_command 'hello \
hi <<\EOF
bye
EOF
haha' listner

	assert_result_equals true 'hello \
hi <<\EOF
bye
EOF
' 'haha'

	assert_equals 'hello \
hi ' "$res_argv"
	assert_equals 'bye
' "$res_stdin"

}

listner() {
	if [ $# = 4 ] && [ command = "$1" ] && [ argv = "$2" ]; then
		res_argv="$3"
	elif [ $# = 5 ] && [ command = "$1" ] && [ heredoc = "$2" ] && [ content = "$3" ]; then
		res_stdin="$4"
	fi
}
