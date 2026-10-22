
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_1() {
	x=
	y=
	shelduck_parse_commands --zero-indent 'shelduck hello 1
x
shelduck wrong 2
y
shelduck bye 3' "hello|bye" listner

	assert_equals 'shelduck hello 1
shelduck bye 3' "$x"

	assert_equals '
x
shelduck wrong 2
y
shelduck bye 3
' "$y"


}

listner() {
	x="${x:-}${x:+
}$1"
	y="${y:-}${y:+
}$3"
	bobshell_result_set true "$2" "$3"




}
