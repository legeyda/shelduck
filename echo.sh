

# test library for debug


shelduck "${SHELDUCK_BASE_URL}/string.sh"

shelduck_echo() {
	shelduck_echo_args="$*"
	printf %s "$shelduck_echo_args" " ($(bobshell_starts_with "$shelduck_echo_args" a && echo starts with a || echo does not start with a))"
	unset shelduck_echo_args
}