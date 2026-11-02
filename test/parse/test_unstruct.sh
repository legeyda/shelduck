
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../src/parse/unstruct.sh

test_01() {
	shelduck_parse_unstruct ''
	assert_result_equals false
}

test_02() {
	shelduck_parse_unstruct hello
	assert_result_equals true hello ''
}

test_03() {
	shelduck_parse_unstruct 'shelduck hello'
	assert_result_equals true 'shelduck hello' ''
}

test_04() {
	shelduck_parse_unstruct 'blabla
shelduck subcmd'
	assert_result_equals true 'blabla
' 'shelduck subcmd'
}
