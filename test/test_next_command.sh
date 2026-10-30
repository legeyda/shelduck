
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh


shelduck import ../src/shelduck.sh

test_next_cmd_1() {
	shelduck_next_command 'header
shelduck hello' '*'
	assert_result_equals true 'header
' 'shelduck hello' ''
}

test_next_cmd_2() {
	shelduck_next_command 'header
shelduck hello
footer' '*'
	assert_result_equals true 'header
' 'shelduck hello
' footer
}


test_next_cmd_3() {
	shelduck_next_command 'shelduck y' 'x y z'
	assert_result_equals true '' 'shelduck y' ''
}

test_next_cmd_4() {
	shelduck_next_command 'shelduck hello' 'bye'
	assert_result_equals false
}

test_next_cmd_5() {
	shelduck_next_command 'header
shelduck hello\
world
footer' '*'
	assert_result_equals true 'header
' 'shelduck hello\
world
' footer
}


test_next_cmd_6() {
	shelduck_next_command 'header
shelduck -a die   -a command_available   -a log hello\
world
shelduck hello again\
world
footer' '*'
	assert_result_equals true 'header
' 'shelduck -a die   -a command_available   -a log hello\
world
' 'shelduck hello again\
world
footer'
}
