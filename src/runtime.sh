
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/strip.sh


shelduck_get_cli() {
	_shelduck_get_cli__shift=0
	_shelduck_get_cli__raw=false
	_shelduck_get_cli__transform=
	_shelduck_get_cli__stdin_flag=false

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
				shelduck_get_cli_transform "${1#$2}"
				shift 2
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 2 ))
				;;

			(-t=*|--transform=*)
				shelduck_get_cli_transform "${1#*=}"
				shift
				_shelduck_get_cli__shift=$(( _shelduck_get_cli__shift + 1 ))
				;;

			(*)
				break
				;;

		esac
	done
}

# fun: shelduck_get_cli_stdin VALUE
shelduck_get_cli_transform() {
	if [ "$1" = - ]; then
		if [ $# -gt 1 ]; then
			bobshell_die 'shelduck_get_cli_transform: when value is "-" (stdin) then single argument expected'
		fi
		if [ true = "${_shelduck_get_cli__stdin_flag:-}" ]; then
			bobshell_die stdin already consumed
		fi
		_shelduck_get_cli__stdin_flag=true
		_shelduck_get_cli_transform__stdin=$(cat)
		set -- "$_shelduck_get_cli_transform__stdin"
		unset _shelduck_get_cli_transform__stdin
	fi
	_shelduck_get_cli__transform="${_shelduck_get_cli__transform:+$bobshell_newline}$*"
}

shelduck_get_cli_clear() {
	unset _shelduck_get_cli__shift _shelduck_get_cli__raw _shelduck_get_cli__transform _shelduck_get_cli__stdin_flag
}



# fun: shelduck_get [ -r | --raw ] URL
# env: base_url
shelduck_get() {

	shelduck_get_cli "$@"
	shift "$_shelduck_get_cli__shift"
	unset _shelduck_get_cli__shift


	bobshell_log_trace "shelduck_get: $*"
	if ! [ $# = 1 ]; then
		bobshell_log_error          'shelduck_get: exactly one positional argument expected'
		shelduck_get_cli_clear
		bobshell_result_set_2 false 'shelduck_get: exactly one positional argument expected'
		return
	fi



	if [ "$1" = - ]; then
		if [ true = "$_shelduck_get_cli__stdin_flag" ]; then
			shelduck_get_cli_clear
			bobshell_die 'stdin alreay consumed'
		fi
		_shelduck_get__result=$(cat)
		if [ false = "$_shelduck_get_cli__raw" ]; then
			shelduck_do_prepare "$_shelduck_get__result"
			if ! bobshell_result_check; then
				bobshell_log_error "shelduck_get: do_prepare failed"
				shelduck_get_cli_clear
				bobshell_result_set_2 false 'shelduck_get: prepare failed'
				return
			fi
		fi
	elif [ false = "$_shelduck_get_cli__raw" ]; then
		shelduck_fix_url "$1" # todo shelduck_fix_url does not return boolean as first result
		shelduck_prepare "$bobshell_result_1"
		if ! bobshell_result_check; then
			bobshell_log_error "shelduck_get: fetch failed"
			shelduck_get_cli_clear
			bobshell_result_set_2 false 'shelduck_get: fetch failed'
		fi
		_shelduck_get__result="$bobshell_result_2"
	else
		shelduck_fix_url "$1" # todo shelduck_fix_url does not return boolean as first result
		shelduck_do_fetch "$bobshell_result_1"
		if ! bobshell_result_check; then
			bobshell_log_error "shelduck_get: prepare failed"
			shelduck_get_cli_clear
			bobshell_result_set_2 false 'shelduck_get: prepare failed'
		fi
		_shelduck_get__result="$bobshell_result_2"
	fi
	unset _shelduck_get_cli__raw

	if [ -n "$_shelduck_get_cli__transform" ]; then
		while [ -n "$_shelduck_get_cli__transform" ]; do
			bobshell_str_split_v3 "$_shelduck_get_cli__transform" "$bobshell_newline"
			if ! bobshell_result_check _shelduck_get__cmd _shelduck_get_cli__transform; then
				_shelduck_get__cmd="$_shelduck_get_cli__transform"
				_shelduck_get_cli__transform=
			fi
			bobshell_str_strip "$_shelduck_get__cmd"
			_shelduck_get__cmd="$bobshell_result_2"
			if [ -z "$_shelduck_get__cmd" ]; then
				continue
			fi
			shelduck_split_args 'shelduck_prepare_transform "$_shelduck_get__result" '"$_shelduck_get__cmd"
			bobshell_result_assert
			eval "$bobshell_result_2"
			bobshell_result_assert
			_shelduck_get__result="$bobshell_result_2"
		done
	fi
	unset _shelduck_get_cli__transform

	shelduck_get_cli_clear
	bobshell_result_set_2 true "$_shelduck_get__result"
	unset  _shelduck_get__result
}


shelduck_include() {
	shelduck_get "$@"
	bobshell_result_assert -- shelduck_include: shelduck_get
	eval "$bobshell_result_2"
}
