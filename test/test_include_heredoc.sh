
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_runtime() {
	test_flag=false
	shelduck run 'val:shelduck include --raw - <<\EOF
	test_flag=true
EOF'

	assert_equals 'true' "$test_flag"
}

# test_compile() {
# 	x=$(shelduck build 'val:shelduck include --raw - <<\EOF
# hello
# EOF
# ')
#
# 	assert_equals 'hello
# ' "$x"
# }
