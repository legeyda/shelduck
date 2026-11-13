
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/event/stop.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/experimental/clifford.sh


bobshell_event_listen shelduck_transform_event 'shelduck_transform_replace_listener "$@"'
bobshell_event_listen shelduck_transform_event 'shelduck_transform_sed_listener "$@"'
bobshell_event_listen shelduck_transform_event 'shelduck_transform_clifford_listener "$@"'


# fun: shelduck_prepare_transform INPUT [ TRANSFORMARGS ]
shelduck_prepare_transform() {
	bobshell_result_set false shelduck transform: command "$2" not supported
	bobshell_event_fire shelduck_transform_event "$@"
	bobshell_result_assert -- transform for $2 not found
}

shelduck_transform_replace_listener() {
	if [ replace = "$2" ]; then
		if [ $# -lt 4 ]; then
			bobshell_result_set_2 false '2 arguments expected'
			return
		fi
		bobshell_str_replace "$1" "$3" "$4"
		bobshell_result_set_2 true "$bobshell_result_2"
		bobshell_event_stop
	fi
}

shelduck_transform_sed_listener() {
	if [ sed = "$2" ]; then
		if ! _shelduck_transform_item__result=$(printf %s "$1" | bobshell_shiftexec 1 "$@"); then
			unset _shelduck_transform_item__result
			_shelduck_prepare_transform__msg='error getting error message'
			_shelduck_prepare_transform__msg=$(printf %s "$_shelduck_prepare_transform__input" | "$@" 1>/dev/null 2>&1) || true
			bobshell_result_set_2 false "sed invocation error: $_shelduck_prepare_transform__msg"
			unset _shelduck_prepare_transform__msg
			return
		fi
		bobshell_result_set_2 true "$_shelduck_transform_item__result"
		unset _shelduck_transform_item__result
		bobshell_event_stop
	fi
}

shelduck_transform_clifford_listener() {
	if [ clifford = "$2" ]; then
		bobshell_clifford_compile "$1"
		bobshell_event_stop
	fi
}
