
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

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
