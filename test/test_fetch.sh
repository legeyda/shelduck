
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_runtime() {
	x=$(shelduck run 'val:shelduck fetch ./test/test_fetch/include1.txt
bobshell_result_assert test_fetch_result
printf %s "$test_fetch_result"
')
	assert_equals hello "$x"
}

test_compile() {
		x=$(shelduck build 'val:
''shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh

''shelduck fetch ./test/test_fetch/include1.txt
bobshell_result_assert test_fetch_result
printf %s "$test_fetch_result"
')

	x=$(sh -euc "$x")
	assert_equals hello "$x"

}
