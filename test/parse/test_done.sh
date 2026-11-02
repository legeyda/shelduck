
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../../src/parse/done.sh

test_01() {
	f=false
	shelduck_parse_done xyz f 1 2 3 a b
	assert_equals 'true 1 2 3 a b' "$f"
	assert_result_equals true a b
}


f() {
	f="true $*"

}
