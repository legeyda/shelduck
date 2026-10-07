
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


. target/shelduck.sh

test_parse_commands_1() {
	shelduck_parse_commands 'hello'
	bobshell_result_assert output -- error calling shelduck_parse_commands
	assert_equals hello "$output"
}

test_parse_commands_2() {
	shelduck_parse_commands 'hello'
	bobshell_result_assert output -- error calling shelduck_parse_commands
	assert_equals hello "$output"
}
