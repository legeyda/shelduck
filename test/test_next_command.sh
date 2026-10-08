
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


. target/shelduck.sh

test_1() {
	shelduck_next_command 'foo
shelduck subcmd hello
baz'
	bobshell_result_assert x y z

	assert_equals 'foo
' "$x"
	assert_equals 'shelduck subcmd hello' "$y"
	assert_equals '
baz' "$z"

}

test_2() {
	shelduck_next_command 'shelduck subcmd hello'
	bobshell_result_assert x y z -- ok expected

	assert_equals '' "$x"
	assert_equals 'shelduck subcmd hello' "$y"
	assert_equals '' "$z"
}

test_3() {
	shelduck_next_command 'hello shelduck subcmd hello'
	#echo DEBUG "$bobshell_result_size" "<$bobshell_result_1>" "<$bobshell_result_2>" "<$bobshell_result_3>" "<$bobshell_result_4>" >&2
	assert_error bobshell_result_check
}

test_4() {
	shelduck_next_command 'shelduck subcmd hello\
world\
foo
done'

	bobshell_result_assert x y z -- ok expected

	assert_equals '' "$x"
	assert_equals 'shelduck subcmd hello\
world\
foo' "$y"
	assert_equals '
done' "$z"
}
