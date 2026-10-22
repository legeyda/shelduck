


shelduck_get_cli() {
	_shelduck_get_cli__tform=true
	_shelduck_get_cli__shift=0
	while [ $# -gt 0 ]; do
		case "$1" in
			(--)
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				break
				;;
			(-t|--transform)
				_shelduck_get_cli__tform=true
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				;;
			(-T|--no-transform)
				_shelduck_get_cli__tform=false
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				;;
			(-*)
				bobshell_die 'shelduck_get_cli: unexpected argument: '"$1"
				;;
			(*)
				break
				;;
		esac
	done
	bobshell_result_set true "$_shelduck_get_cli__shift" "$_shelduck_get_cli__tform"
	unset _shelduck_get_cli__shift _shelduck_get_cli__tform
}

# fun: shelduck_get [ -t | --transform | -T | --no-transform] URL
# env: base_url
shelduck_get() {

	shelduck_get_cli "$@"
	bobshell_result_assert
	shift "$bobshell_result_2"
	_shelduck_include__transform="${bobshell_result_3:-true}"

	bobshell_log_trace "shelduck_get: $*"
	if [ $# != 1 ]; then
		bobshell_log_error          'shelduck_get: exactly one positional argument expected'
		bobshell_result_set_2 false 'shelduck_get: exactly one positional argument expected'
		return
	fi

	shelduck_fix_url "$1" # todo shelduck_fix_url does not return boolean as first result
	if [ true = "$_shelduck_include__transform" ]; then
		shelduck_prepare "$bobshell_result_1"
		if ! bobshell_result_check _shelduck_get__result; then
			bobshell_log_error "shelduck_get: fetch failed"
			bobshell_result_set_2 false 'shelduck_get: fetch failed'
		fi
		bobshell_result_set_2 true "$bobshell_result_2"
	else
		shelduck_do_fetch "$bobshell_result_1"
		if ! bobshell_result_check _shelduck_get__result; then
			bobshell_log_error "shelduck_get: prepare failed"
			bobshell_result_set_2 false 'shelduck_get: prepare failed'
		fi
		bobshell_result_set_2 true "$bobshell_result_2"
	fi
	unset _shelduck_include__transform _shelduck_get__input

}


shelduck_include() {
	shelduck_get "$@"
	bobshell_result_assert -- shelduck_include: shelduck_get
	eval "$bobshell_result_2"
}
