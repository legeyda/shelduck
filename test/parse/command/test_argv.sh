
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../../src/parse/command/argv.sh

test_1() {
	shelduck_parse_command_argv hello
	assert_result_equals true hello ''
}

test_2() {
	shelduck_parse_command_argv 'hello
hi'
	assert_result_equals true 'hello
' hi
}

test_3() {
	shelduck_parse_command_argv 'hello \
hi
bye'
	assert_result_equals true 'hello \
hi
' bye
}

test_4() {
	shelduck_parse_command_argv 'hello \
hi <<EOF
bye'
	assert_result_equals true 'hello \
hi ' '<<EOF
bye'
}
