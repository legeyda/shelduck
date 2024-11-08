# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit shelduck.sh.in and run sh ./run build to regenerate it


# https://github.com/ajdiaz/bashdoc
shelduck() {
	if [ -z "${1:-}" ]; then
		shelduck_usage >&2
		return 1
	fi
	

	shelduck_load "$@"
	eval "$shelduck_load_result"
	unset shelduck_load_result

}

shelduck_eval() {
	bobshell_die not implemented
}



shelduck_usage() {
	printf %s 'Usage: shelduck URL [ALIAS...]'
}



# use: shelduck_load URL [ALIAS...]
# use: echo "$shelduck_load_result"
# env: shelduck_load_alias_strategy
#      shelduck_load_base_url
shelduck_load() {
	# mark recursive function enter
	: "${shelduck_load_depth:=0}"
	if [ 0 -eq "$shelduck_load_depth" ]; then
		shelduck_load_alias_strategy=wrap
		shelduck_load_base_url="${SHELDUCK_BASE_URL:-}"
	else
		shelduck_load_alias_strategy=rename
		shelduck_load_base_url="$shelduck_load_previous_url"
	fi
	shelduck_load_depth=$(( 1 + shelduck_load_depth ))



	# load script body
	bobshell_resolve_url_result=
	bobshell_resolve_url "$1" "$shelduck_load_base_url"
	shelduck_load_url="$bobshell_resolve_url_result"
	unset bobshell_resolve_url_result
	shift
	shelduck_load_result=$(shelduck_cached_fetch_url "$shelduck_load_url")

	# analyze functions
	shelduck_load_regex='^ *([A-Za-z0-9_]+) *\( *\) *\{ *$' # match shell function declaration '  function_name  (   )  {  '
	shelduck_load_function_names="$(printf %s "$shelduck_load_result" | sed --silent --regexp-extended "s/$shelduck_load_regex/\1/p")"
	unset shelduck_load_regex
	# todo detect function name collizion and print warning if so
	
	# handle aliases
	for arg in "$@"; do
		# todo assert $arg not empty
		if ! bobshell_split_key_value "$arg" = key value; then
			key="$arg"
			value="$arg"
		fi
		shelduck_require_not_empty "$key"   line "$arg": key   expected not to be empty
		shelduck_require_not_empty "$value" line "$arg": value expected not to be empty
		
		shelduck_function_name="$(printf %s "$shelduck_load_function_names" | grep -E "^.*$value\$")"
		if [ -n "$shelduck_function_name" ]; then
			if [ wrap = "$shelduck_load_alias_strategy" ]; then
			shelduck_load_result="$shelduck_load_result

$key() {
	$shelduck_function_name \"\$@\";
}
"
			else
				shelduck_die "shelduck_load_alias_strategy: value $shelduck_load_alias_strategy not supported"
			fi
		fi
		unset shelduck_function_name
	done
	unset shelduck_load_url shelduck_load_function_names

	# mark recursive function exit
	shelduck_load_depth=$(( -1 + shelduck_load_depth ))
	if [ 0 -eq "$shelduck_load_depth" ]; then
		unset shelduck_load_depth shelduck_load_previous_url
	else
		shelduck_load_previous_url="$shelduck_load_url"
	fi
}




shelduck_cached_fetch_url() {
	# bypass cache if local file
	if bobshell_starts_with "$1" 'file://' file_name; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		cat "$file_name"
		unset file_name
		return
	fi
	# todo implement cache
	# todo timeout
	bobshell_fetch_url "$1"
}






# FILE DOWNLOAD





# UTILS

shelduck_die() {
  # https://github.com/biox/pa/blob/main/pa
  printf '%s: %s.\n' "$(basename "$0")" "${*:-error}" >&2
  exit 1
}


# REQUIREMENTS

shelduck_require_not_empty() {
	if [ -z "${1:-}" ]; then
		shift
		die "$@"
	fi
}





# shellcheck disable=SC2148

# disable recursive dependency resolution when building shelduck itself
# shelduck ./base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck ./string.sh


bobshell_fetch_url() {
	if bobshell_starts_with "$1" 'file://' file_name; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		cat "$file_name"
		unset file_name
	elif bobshell_command_available curl; then
		bobshell_fetch_url_with_curl "$1"
	elif bobshell_command_available wget; then
		bobshell_fetch_url_with_wget "$1"
	else
		bobshell_die 'error: neither curl nor wget installed'
	fi
}

#fun: bobshell_resolve_url URL [BASEURL]
bobshell_resolve_url() {
	if         bobshell_starts_with "$1" file:// \
			|| bobshell_starts_with "$1" http:// \
			|| bobshell_starts_with "$1" https:// \
			|| bobshell_starts_with "$1" ftp:// \
			|| bobshell_starts_with "$1" ftps:// \
			; then
		bobshell_resolve_url_result="$1"
	elif [ -n "${2:-}" ]; then
		bobshell_resolve_url_result="$2"
		if ! bobshell_ends_with "$bobshell_resolve_url_result" /; then
			bobshell_resolve_url_result="${bobshell_resolve_url_result%/*}/"
		fi
		bobshell_resolve_url_result="$bobshell_resolve_url_result$1"
	else
		bobshell_die "bobshell_resolve_url: url is relaive, but not base url defined: $1" 
	fi
}

bobshell_fetch_url_with_curl() {
	curl --fail --silent --show-error --location "$1"
}

bobshell_fetch_url_with_wget() {
	wget --no-verbose --output-document -
}



# STRING MANUPULATION

# disable recursive dependency resolution when building shelduck itself
# shelduck base.sh

# use: bobshell_starts_with hello he rest && echo "$rest" # prints llo
bobshell_starts_with() {
	set -- "$1" "$2" "${3:-}" "${1##"$2"}"
	if [ -n "$2" ] && [ "$1" = "$4" ]; then
		return 1
	fi
	if [ -n "${3:-}" ]; then
		bobshell_putvar "$3" "$4"
	fi
}

bobshell_ends_with() {
	set -- "$1" "$2" "${3:-}" "${1%%"$2"}"
	if [ -n "$2" ] && [ "$1" = "$4" ]; then
		return 1
	fi
	if [ -n "${3:-}" ]; then
		bobshell_putvar "$3" "$4"
	fi
}


bobshell_split_key_value() {
	set -- "$1" "$2" "$3" "$4" "${1%%"$2"*}"
	if [ "$1" = "$5" ]; then
		return 1
	fi
	bobshell_putvar "$3" "$5"
	bobshell_putvar "$4" "${1#*"$2"}"
}


# txt: regex should be in the basic form (https://www.gnu.org/software/grep/manual/html_node/Basic-vs-Extended.html)
#      ^ is implicitly prepended to regexp
#      https://stackoverflow.com/questions/35693980/test-for-regex-in-string-with-a-posix-shell#comment86337738_35694108
bobshell_is_regex_match() {
	bobshell_is_regex_match_amount=$(expr "$1" : "$2")
	test "$bobshell_is_regex_match_amount" = "${#1}"
}


# todo


bobshell_die() {
  # https://github.com/biox/pa/blob/main/pa
  printf '%s: %s.\n' "$(basename "$0")" "${*:-error}" >&2
  exit 1
}


# use isset unreliablevar
bobshell_isset() {
	eval "test '\${$1+defined}' = defined"
}


bobshell_command_available() {
	command -v "$1" > /dev/null
}

# fun: bobshell_putvar VARNAME NEWVARVALUE
# txt: установка значения переменной по динамическому имени
bobshell_putvar() {
  eval "$1='$2'"
}

# fun bobshell_getvar VARNAME
# use: echo "$(getvar MSG)"
# txt: считывание значения переменной по динамическому имени
bobshell_getvar() {
  eval "printf %s \"\$$1\""
}


