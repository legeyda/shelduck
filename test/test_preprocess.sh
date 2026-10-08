
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../shelduck.sh

test_1() {
	x='foo
shelduck blabla replace a b
baz'
	shelduck_preprocess "$x"
	bobshell_result_assert res
	assert_equals "$x" "$res"
}


test_2() {

	shelduck_preprocess 'foo
shelduck preprocess replace a b
baz'
	bobshell_result_assert res
	assert_equals 'foo

bbz' "$res"





}
