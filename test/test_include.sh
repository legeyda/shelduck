
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_runtime() {
	x=$(shelduck run 'val:
greet() {
	printf %s "$@"
}
''shelduck include ./test/test_include/include1.txt
''shelduck include ./test/test_include/include1.txt
')
	assert_equals 'hellohello' "$x"
}

test_compile() {
		x=$(shelduck build 'val:
greet() {
	printf %s "$@"
}

''shelduck include ./test/test_include/include1.txt
''shelduck include ./test/test_include/include1.txt'
)

	x=$(sh -euc "$x")
	assert_equals 'hellohello' "$x"

}
