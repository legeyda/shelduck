
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh



test_compile() {
	unset fun_x fun_f fun_args
	fun --param=1 --flag aaa
	assert_equals 1 "$fun_x"
	assert_equals true "$fun_f"
	assert_equals aaa "$fun_args"
}



fun() {
shelduck include --transform=clifford - "$@" <<\EOF
	param p param
	var fun_x
	flag f flag
	var fun_f
EOF

	fun_args="$*"

}
