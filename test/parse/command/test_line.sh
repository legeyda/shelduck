
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../../src/parse/command/line.sh

test_1() {
	shelduck_parse_command_line ''
	assert_result_equals false
}

test_2() {
	shelduck_parse_command_line hello
	assert_result_equals true hello ''
}

test_3() {
	shelduck_parse_command_line 'hello <<EOF'
	assert_result_equals true 'hello ' '<<EOF'
}

test_4() {
	shelduck_parse_command_line 'hello << E O F'
	assert_result_equals true 'hello << E O F' ''
}
