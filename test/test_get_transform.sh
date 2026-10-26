
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_runtime() {
	x=$(shelduck run 'val:shelduck get --transform="replace l j" ./test/test_get/include1.txt
bobshell_result_assert test_get_result
printf %s "$test_get_result"
')
	assert_equals hejjo "$x"
}

test_compile() {
		x=$(shelduck build 'val:
''shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh

''shelduck get --transform="replace l j" ./test/test_get/include1.txt
bobshell_result_assert test_get_result
printf %s "$test_get_result"
')


	x=$(sh -euc "$x")
	assert_equals hejjo "$x"

}
