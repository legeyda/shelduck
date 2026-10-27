
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/strip.sh


shelduck_get_cli() {
	_shelduck_get_cli__shift=0
	_shelduck_get_cli__raw=false
	_shelduck_get_cli__transform=

	while [ $# -gt 0 ]; do
		case "$1" in

			(--)
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				break
				;;

			(-r|--raw)
				_shelduck_get_cli__raw=true
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				;;

			(-t|--transform)
				if [ $# -lt 2 ]; then
					bobshell_die "value expected: $1"
				fi
				_shelduck_get_cli__transform="${_shelduck_get_cli__transform:+$bobshell_newline}${1#$2}"
				shift 2
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 2 ))
				;;

			(-t=*|--transform=*)
				_shelduck_get_cli__transform="${_shelduck_get_cli__transform:+$bobshell_newline}${1#*=}"
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
	bobshell_result_set_4 true "$_shelduck_get_cli__shift" "$_shelduck_get_cli__raw" "$_shelduck_get_cli__transform"
	unset _shelduck_get_cli__shift _shelduck_get_cli__raw _shelduck_get_cli__transform
}

# fun: shelduck_get [ -r | --raw ] URL
# env: base_url
shelduck_get() {

	shelduck_get_cli "$@"
	bobshell_result_assert - _shelduck_get__raw _shelduck_get__transform -- parse cli failed
	shift "$bobshell_result_2"


	bobshell_log_trace "shelduck_get: $*"
	if ! [ $# = 1 ]; then
		bobshell_log_error          'shelduck_get: exactly one positional argument expected'
		bobshell_result_set_2 false 'shelduck_get: exactly one positional argument expected'
		return
	fi

	shelduck_fix_url "$1" # todo shelduck_fix_url does not return boolean as first result
	if [ false = "$_shelduck_get__raw" ]; then
		shelduck_prepare "$bobshell_result_1"
		if ! bobshell_result_check; then
			bobshell_log_error "shelduck_get: fetch failed"
			bobshell_result_set_2 false 'shelduck_get: fetch failed'
		fi
		_shelduck_get__result="$bobshell_result_2"
	else
		shelduck_do_fetch "$bobshell_result_1"
		if ! bobshell_result_check; then
			bobshell_log_error "shelduck_get: prepare failed"
			bobshell_result_set_2 false 'shelduck_get: prepare failed'
		fi
		_shelduck_get__result="$bobshell_result_2"
	fi
	unset _shelduck_get__raw

	if [ -n "$_shelduck_get__transform" ]; then
		while [ -n "$_shelduck_get__transform" ]; do
			bobshell_str_split_v3 "$_shelduck_get__transform" "$bobshell_newline"
			if ! bobshell_result_check _shelduck_get__cmd _shelduck_get__transform; then
				_shelduck_get__cmd="$_shelduck_get__transform"
				_shelduck_get__transform=
			fi
			bobshell_str_strip "$_shelduck_get__cmd"
			_shelduck_get__cmd="$bobshell_result_1"
			if [ -z "$_shelduck_get__cmd" ]; then
				continue
			fi
			shelduck_split_args 'shelduck_prepare_transform "$_shelduck_get__result" '"$_shelduck_get__cmd"
			bobshell_result_assert
			eval "$bobshell_result_2"
			bobshell_result_assert
			_shelduck_get__result="$bobshell_result_2$bobshell_result_3"
		done
	fi
	unset _shelduck_get__transform

	bobshell_result_set_2 true "$_shelduck_get__result"
	unset  _shelduck_get__result
}


shelduck_include() {
	shelduck_get "$@"
	bobshell_result_assert -- shelduck_include: shelduck_get
	eval "$bobshell_result_2"
}
