
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_1() {
	x='
foo
shelduck transform replace a b
baz'
	shelduck_transform "$x" http://url
	bobshell_result_assert res
	assert_equals '
foo

bbz' "$res"

}

test_2() {
	x='
'"shelduck transform replace 'shelduck import bsh://' 'shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/'
""shelduck import bsh://str/quote.sh
"
	x=$(shelduck build "val:$x")
	assert_contains "$x" 'bobshell_str_split_v2()'
}


test_3() {
	x='foo
shelduck blabla replace a b
baz'
	shelduck_transform "$x"
	bobshell_result_assert res
	assert_equals "$x" "$res"
}


test_4() {

	shelduck_transform 'foo
shelduck transform replace a b
baz'
	bobshell_result_assert res
	assert_equals 'foo

bbz' "$res"

}
