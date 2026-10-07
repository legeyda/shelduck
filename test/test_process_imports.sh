
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


. target/shelduck.sh

test_process_imports_1() {
	shelduck_process_imports 'hello'
	bobshell_result_assert output -- error calling shelduck_process_import
	assert_equals hello "$output"
}

test_process_imports_2() {
	shelduck_process_imports 'hello'
	bobshell_result_assert output -- error calling shelduck_process_import
	assert_equals hello "$output"
}
