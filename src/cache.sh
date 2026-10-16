


################ CACHING ####################

# fun: shelduck_cache_get CACHENAME FILEPATH
shelduck_cache_fget() {
	shelduck_mcache_get "$@"
	if bobshell_result_check; then
		return
	fi

	shelduck_fcache_fget "$@"
	if bobshell_result_check _shelduck_cache_fget; then
		shelduck_mcache_put "$@" "$_shelduck_cache_fget"
		bobshell_result_set_2 true "$_shelduck_cache_fget"
		unset _shelduck_cache_fget
		return
	fi
}

# fun: shelduck_cache_get CACHENAME KEY
shelduck_cache_get() {
	shelduck_mcache_get "$@"
	if bobshell_result_check; then
		return
	fi

	shelduck_fcache_get "$@"
	if bobshell_result_check _shelduck_cache_get; then
		shelduck_mcache_put "$@" "$_shelduck_cache_get"
		bobshell_result_set_2 true "$_shelduck_cache_get"
		unset _shelduck_cache_get
		return
	fi
}

shelduck_cache_put() {
	shelduck_mcache_put "$@"
	shelduck_fcache_put "$@"
}



################ shelduck memory cache ####################

: "${_shelduck_mcache_key:=undefined}"
#: "${_shelduck_mcache_hash:=undefined}"

# env: _shelduck_mcache_key
# env: _shelduck_mcache_hash
shelduck_mcache_key() {
	case "$1" in
		("$_shelduck_mcache_key") ;;
		(*)
			_shelduck_mcache_key="$1"
			_shelduck_mcache_hash="${#1}"
			if [ "$_shelduck_mcache_hash" -lt 10 ]; then
				_shelduck_mcache_key__tmp="${_shelduck_mcache_key#${_shelduck_mcache_key%???????????????}}" # 15
				_shelduck_mcache_hash=$(( 31 * _shelduck_mcache_hash + $(printf %d "'$_shelduck_mcache_key__tmp") ))

				_shelduck_mcache_key__tmp="${_shelduck_mcache_key__tmp#?????}"
				_shelduck_mcache_hash=$(( 31 * _shelduck_mcache_hash + $(printf %d "'$_shelduck_mcache_key__tmp") ))

				_shelduck_mcache_key__tmp="${_shelduck_mcache_key__tmp#?????}"
				_shelduck_mcache_hash=$(( 31 * _shelduck_mcache_hash + $(printf %d "'$_shelduck_mcache_key__tmp") ))

				unset _shelduck_mcache_key__tmp
			else
				_shelduck_mcache_hash=$(cksum <<EOF_shelduck_mcache_key
$1
EOF_shelduck_mcache_key
)
				for _shelduck_mcache_hash in $_shelduck_mcache_hash; do
					break
				done

			fi
			;;
	esac
}

# fun: shelduck_mcache_get CACHENAME KEY
shelduck_mcache_get() {
	shelduck_mcache_key "$2"

	_shelduck_mcache_get="$1"
	shift
	set -- "${_shelduck_mcache_get}_search_${_shelduck_mcache_hash}_event" "$@"
	unset _shelduck_mcache_get

	bobshell_result_set_1 false
	bobshell_event_fire "$@"
}

# fun: shelduck_mcache_add CACHENAME KEY VALUE
shelduck_mcache_put() {
	shelduck_mcache_key "$2"

	bobshell_str_quote "$3"
	_shelduck_mcache_put__quoted_value="$bobshell_result_1"

	bobshell_event_listen "${1}_search_${_shelduck_mcache_hash}_event" eval '
if [ "$1" = '"$_shelduck_mcache_hash"' ]; then
bobshell_result_set_2 true '"$_shelduck_mcache_put__quoted_value"'
bobshell_event_stop
fi
'
	unset _shelduck_mcache_put__quoted_value

	bobshell_result_set true "$3"
}



################ shelduck file cache ####################


: "${_shelduck_fcache_key:=undefined}"

# env: _shelduck_fcache_key
# env: _shelduck_fcache_hash
shelduck_fcache_key() {
	case "$1" in
		("$_shelduck_fcache_key") ;;
		(*)
			_shelduck_fcache_key="$1"
			bobshell_str_match "$_shelduck_fcache_key" 'https://raw.githubusercontent.com/*'
			if [ true = "$bobshell_result_1" ]; then
				: # todo s|^https://raw.githubusercontent.com/\(.*\)/\(.*\)/refs/heads/\(.*\)|github_\1_\2_\3|g;
			fi
			_shelduck_fcache_hash=$(sed 's/[\/<>:\\|?*]/-/g' <<EOF_shelduck_fcache_key
$_shelduck_fcache_key
EOF_shelduck_fcache_key
)
			;;
	esac
}

# fun: shelduck_fcache_fget CACHENAME FILEPATH
shelduck_fcache_fget() {
	shelduck_fcache_key "$2"
	_shelduck_fcache_fget__file="$shelduck_cache_dir/$1/$_shelduck_fcache_hash"

	if ! [ -f "$_shelduck_fcache_fget__file" ]; then
		bobshell_result_set_2 false "file not found: $_shelduck_fcache_fget__file"
		unset _shelduck_fcache_fget__file
		return
	fi

	if ! [ "$_shelduck_fcache_fget__file" -nt "$2" ]; then
		bobshell_result_set_2 false "file "$_shelduck_fcache_fget__file" is not newer than $2"
		unset _shelduck_fcache_fget__file
		return
	fi
	unset _shelduck_fcache_fget__file

	shelduck_fcache_get
}

# fun: shelduck_fcache_put CACHENAME KEY VALUE
shelduck_fcache_put() {
	shelduck_fcache_key "$2"
	_shelduck_fcache_put__file="$shelduck_cache_dir/$1/$_shelduck_fcache_hash"
	{
		_shelduck_fcache_put__now="$(date +%s)"
		printf '# timestamp: %s\n' "$_shelduck_fcache_put__now"
		unset _shelduck_fcache_put__now
		printf %s "$3"
	} > "$_shelduck_fcache_put__file"
	unset _shelduck_fcache_put__file
}


# fun: shelduck_fcache_get CACHENAME KEY
# res: true VALUE
# res: false
shelduck_fcache_get() {
	shelduck_fcache_key "$2"
	_shelduck_fcache_get__file="$shelduck_cache_dir/$1/$_shelduck_fcache_hash"

	if ! [ -f "$_shelduck_fcache_get__file" ]; then
		bobshell_result_set_2 false "file not found: $_shelduck_fcache_get__file"
		unset _shelduck_fcache_get__file
		return
	fi

	{
		unset _shelduck_fcache_get__file
		if ! read -r _shelduck_fcache_get__fts; then
			bobshell_result_set_2 false 'file is not readable or empty'
			return
		fi

		bobshell_str_prefix "$_shelduck_fcache_get__fts" '# timestamp: '
		if ! bobshell_result_check _shelduck_fcache_get__fts; then
			unset _shelduck_fcache_get__fts
			bobshell_result_set_2 false 'wrong timestamp format'
			return
		fi

		_shelduck_fcache_get__deadline="$(date +%s)"
		_shelduck_fcache_get__deadline=$(( _shelduck_fcache_get__deadline - shelduck_cache_ttl ))
		if ! [ "$_shelduck_fcache_get__fts" -gt "$_shelduck_fcache_get__deadline" ]; then
			unset _shelduck_fcache_get__fts _shelduck_fcache_get__deadline
			bobshell_result_set_2 false 'file expired'
			return
		fi
		unset _shelduck_fcache_get__fts _shelduck_fcache_get__deadline

		_shelduck_fcache_get__result=$(cat)
		bobshell_result_set_2 true "$_shelduck_fcache_get__result"

	} < "$_shelduck_fcache_get__file"
}
