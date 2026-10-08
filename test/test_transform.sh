
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../shelduck.sh

test_1() {
	x='
foo
shelduck preprocess replace a b
baz'
	shelduck_transform "$x" http://url
	bobshell_result_assert res
	assert_equals '

# shelduck: script http://url

foo

bbz
# shelduck: end of script http://url

' "$res" "$res"
}
