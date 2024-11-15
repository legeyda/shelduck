#!/bin/sh
set -eu
# script used quick testing

shelduck import -a die \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh

shelduck import -a starts_with \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh


shelduck_test_echo() {
	shelduck_echo_args="$*"
	if [ -z "$shelduck_echo_args" ]; then
		die 'shelduck_echo: no args provided'
	fi
	printf %s "$shelduck_echo_args" " ($(starts_with "$shelduck_echo_args" a && echo starts with a || echo does not start with a))"
	unset shelduck_echo_args
}