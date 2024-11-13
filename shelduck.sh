# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit shelduck.sh.in and run sh ./run build to regenerate it


# see https://github.com/ajdiaz/bashdoc


# fun: shelduck CLIARGS...
# api: public
shelduck() {
	shelduck_eval "$@"
}



# api: public
shelduck_usage() {
	printf %s 'Usage: shelduck URL [ALIAS...]'
}



# fun: shelduck_eval CLIARGS...
# api: public
shelduck_eval() {
	shelduck_eval_script=$(shelduck_resolve "$@")
	eval "$shelduck_eval_script"
	unset shelduck_eval_script
}



# fun: shelduck_resolve CLIARGS...
# api: public
shelduck_resolve() {
	# set starting parameters
	shelduck_url_history=
	shelduck_alias_strategy="${SHELDUCK_ALIAS_STRATEGY:-wrap}"
	
	# delegate
	shelduck_print "${SHELDUCK_BASE_URL:-}" "$@"
}



# fun: shelduck_print BASEURL CLIARGS...
# env: shelduck_url_history
#      shelduck_alias_strategy
# txt: parse cli and delegate to shelduck_print_tree
# api: private
shelduck_print() {
	shelduck_print_base_url="$1"
	shift

	shelduck_parse_cli "$@"
	shelduck_parse_cli_url=$(bobshell_resolve_url "$shelduck_parse_cli_url" "$shelduck_print_base_url")
	set -- "$shelduck_parse_cli_url" "$shelduck_parse_cli_aliases"
	unset shelduck_print_base_url shelduck_parse_cli_url shelduck_parse_cli_aliases
	
	# load script
	shelduck_print_script=$(shelduck_print_origin "$@")
	set -- "$shelduck_print_script" "$@"
	unset shelduck_print_script

	# check if dependency was already compiled
	if ! bobshell_contains "$shelduck_url_history" "$2"; then
		shelduck_compile "$@"
		shelduck_url_history="$shelduck_url_history $2"
	fi

	# print additions, if needed
	shelduck_print_addition "$@"
}

# fun: shelduck_parse_cli [CLIARGS...]
# env: shelduck_parse_cli_url
#      shelduck_parse_cli_aliases
# api: private
shelduck_parse_cli() {
	# parse cli, save to local array: ABSURL [ALIAS...]
	shelduck_parse_cli_url=
	shelduck_parse_cli_aliases=
	while [ "${1+defined}" = defined ]; do
		case "$1" in
			-a|--alias)
				shift;
				if [ -z "${1:-}" ]; then
					bobshell_die "alias argument expected to be not empty"
				fi
				shelduck_parse_cli_aliases="$shelduck_parse_cli_aliases $1"
				shift
				;;
			*)
				if [ -z "${1:-}" ]; then
					bobshell_die "url expected to be nonempty"
				fi
				if [ -n "$shelduck_parse_cli_url" ]; then
					bobshell_die "only one url allowed $1"
				fi
				shelduck_parse_cli_url="$1"
				shift
				;;
		esac
	done
	if [ -z "$shelduck_parse_cli_url" ]; then
		bobshell_die "url expected to set"
	fi
}



# fun: shelduck_compile SCRIPT ABSURL ALIASES
# txt: print recusively expanded shelduck commands, and print rewritten rest of script
# api: private
shelduck_compile() {
	shelduck_compile_input="$1"
	shift
	if bobshell_starts_with "$shelduck_compile_input" "$bobshell_newline"; then
		printf '%s\n' "# shelduck: source for $1"	
	fi

	shelduck_compile_before=
	shelduck_compile_after=
	while true; do
		if bobshell_starts_with "$shelduck_compile_input" 'shelduck ' shelduck_compile_after; then
			shelduck_compile_input="$shelduck_compile_after"
		elif ! bobshell_split2 "$shelduck_compile_input" "${bobshell_newline}shelduck " shelduck_compile_before shelduck_compile_after; then
			break
		else

			# print everything before the first found shelduck command
			shelduck_rewrite "$shelduck_compile_before$bobshell_newline" "$@"
			shelduck_compile_input="$shelduck_compile_after$bobshell_newline"
		
		fi

		

		shelduck_compile_command=
		while true; do
			if ! bobshell_split2 "$shelduck_compile_input" "${bobshell_newline}" shelduck_compile_before shelduck_compile_after; then
				shelduck_compile_command="$shelduck_compile_input"
				shelduck_compile_input=
				break
			fi

			if ! bobshell_ends_with "$shelduck_compile_before" '\' shelduck_compile_before; then
				shelduck_compile_command="$shelduck_compile_command$shelduck_compile_before"
				shelduck_compile_input="$bobshell_newline$shelduck_compile_after"
				break;
			fi
			
			shelduck_compile_command="$shelduck_compile_command${shelduck_compile_before}"
			shelduck_compile_input="$shelduck_compile_after"

		done
		
		# assert shelduck argument command line not empty
		if [ -z "$shelduck_compile_command" ]; then
			bobshell_die 'empty shelduck arguments'
		fi

		# get base url to pass ot depenencies
		shelduck_compile_base_url=
		if [ -n "$1" ]; then
			shelduck_compile_base_url=$(bobshell_base_url "$1")
		fi

		# before recursive call, save variables to local array
		set -- "$shelduck_compile_input" "$@"

		# recursive call, concously not double qouting
		# shellcheck disable=SC2086
		shelduck_print "$shelduck_compile_base_url" $shelduck_compile_command

		# after recursive call, restore variables from local array
		shelduck_compile_input="$1"
		shift
	done
				

	# print everything after last found shelduck command
	shelduck_rewrite "$shelduck_compile_input" "$@"
}





# fun: shelduck_print_origin ABSURL
# txt: prints original script without modification
# api: private
shelduck_print_origin() {
	shelduck_cached_fetch_url "$1"
}




# fun: shelduck_rewrite ORIGCONTENT URL ALIASES
# txt: rewrite original script (e.g. rename functions)
# api: private
shelduck_rewrite() {
	if [ rename = "${shelduck_alias_strategy:-}" ]; then
		bobshell_die "shelduck_alias_strategy: value $shelduck_alias_strategy not supported"
	fi
	# comment out shelduck dependency directive
	printf %s "$1"
}




# fun: shelduck_print_addition ORIGCONTENT ABSURL ALIASES
# txt: print script additional code (e.g. aliases)
# api: private
shelduck_print_addition() {

	if [ wrap != "$shelduck_alias_strategy" ]; then
		# nothing to do, wrap was the only supported customization
		return
	fi

	# analyze functions (for aliases)
	regex='^ *([A-Za-z0-9_]+) *\( *\) *\{ *$' # match shell function declaration '  function_name  (   )  {  '
	shelduck_print_addition_function_names="$(printf %s "$1" | sed --silent --regexp-extended "s/$regex/\1/p")"
	unset regex
	# todo detect function name collizion and print warning if so
	

	# analyze aliases
	for arg in $3; do
		# todo assert $arg not empty
		if ! bobshell_split2 "$arg" = key value; then
			key="$arg"
			value="$arg"
		fi
		bobshell_require_not_empty "$key"   line "$arg": key   expected not to be empty
		bobshell_require_not_empty "$value" line "$arg": value expected not to be empty
		
		shelduck_print_script_function_name="$(printf %s "$shelduck_print_addition_function_names" | grep -E "^.*$value\$" || true)"
		if [ -n "$shelduck_print_script_function_name" ] && [ "$key" != "$shelduck_print_script_function_name" ]; then
			printf '\n\n'
			printf '\n # shelduck: alias for %s (from %s)' "$shelduck_print_script_function_name" "$2" 
			printf '\n%s() {' "$key"
			printf '\n	%s "$@"' "$shelduck_print_script_function_name"
			printf '\n}'
			printf '\n'
		fi
		unset key value shelduck_print_script_function_name
	done
	unset shelduck_print_addition_function_names
}




# fun: shelduck_cached_fetch_url ABSURL
# txt: download dependency given url and save to cache
# api: private
shelduck_cached_fetch_url() {
	# bypass cache if local file
	if bobshell_starts_with "$1" 'file://' file_name; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		if ! [ -f "$file_name" ]; then
			bobshell_die "shelduck: dependency fetch error '$1': file '$file_name' not found"
		fi
		cat "$file_name" || bobshell_die "shelduck: dependency fetch error '$1': error loading '$file_name'"
		unset file_name
		return
	fi
	# todo implement cache
	# todo timeout
	bobshell_fetch_url "$1" || bobshell_die "shelduck: dependency fetch error '$1': error downloading '$1'"
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

# fun: bobshell_base_url http://domain/dir/file # prints http://domain/dir/
bobshell_base_url() {
	printf %s/ "${1%/*}"
}


#fun: bobshell_resolve_url URL [BASEURL]
bobshell_resolve_url() {
	if         bobshell_starts_with "$1" file:// \
			|| bobshell_starts_with "$1" http:// \
			|| bobshell_starts_with "$1" https:// \
			|| bobshell_starts_with "$1" ftp:// \
			|| bobshell_starts_with "$1" ftps:// \
			; then
		printf %s "$1"
	elif [ -n "${2:-}" ]; then
		printf %s "$2"
		if ! bobshell_ends_with "$2" /; then
			printf '/'
		fi
		bobshell_resolve_url_value="$1"
		while bobshell_starts_with "$bobshell_resolve_url_value" './' bobshell_resolve_url_value; do
			true
		done
		printf %s "$bobshell_resolve_url_value"
		unset bobshell_resolve_url_value
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

# fun: bobshell_substr STR RANGE OUTPUTVAR
bobshell_substr() {
	
	set -- "$1"
	bobshell_substr_result=$(printf %s "$1" | cut -c "$2-$3")
	col2="$(printf 'foo    bar  baz\n' | cut -c 8-12)"

	unset bobshell_substr_result
}


bobshell_split2() {
	bobshell_require_not_empty "${2:-}" separator should not be empty
	set -- "$1" "$2" "${3:-}" "${4:-}" "${1%%"$2"*}"
	if [ "$1" = "$5" ]; then
		return 1
	fi
	if [ -n "${3:-}" ]; then
		bobshell_putvar "$3" "$5"
	fi
	if [ -n "${4:-}" ]; then
		bobshell_putvar "$4" "${1#*"$2"}"
	fi
}


# txt: regex should be in the basic form (https://www.gnu.org/software/grep/manual/html_node/Basic-vs-Extended.html)
#      ^ is implicitly prepended to regexp
#      https://stackoverflow.com/questions/35693980/test-for-regex-in-string-with-a-posix-shell#comment86337738_35694108
bobshell_is_regex_match() {
	bobshell_is_regex_match_amount=$(expr "$1" : "$2")
	test "$bobshell_is_regex_match_amount" = "${#1}"
}



# fun: shelduck_for_each_line STR SEPARATOR VAR COMMAND
# txt: supports recursion
bobshell_for_each_part() {
	while [ -n "$1" ]; do
		if ! bobshell_split2 \
				"$1" \
				"$2" \
				bobshell_for_each_part_current \
				bobshell_for_each_part_rest; then
			# shellcheck disable=SC2034
			# part used in eval
			bobshell_for_each_part_current="$1"
			bobshell_for_each_part_rest=
		fi
		bobshell_for_each_part_separator="$2"
		bobshell_for_each_part_varname="$3"
		shift 3
		bobshell_for_each_part_command="$*"
		set -- "$bobshell_for_each_part_rest" "$bobshell_for_each_part_separator" "$bobshell_for_each_part_varname" "$@"
		bobshell_putvar "$bobshell_for_each_part_varname" "$bobshell_for_each_part_current"
		$bobshell_for_each_part_command
	done
	unset bobshell_for_each_part_rest bobshell_for_each_part_separator bobshell_for_each_part_varname bobshell_for_each_part_command "$3"
}


# txt: заменить в $1 все вхождения строки $2 на строку $3 и записать результат в переменную $4
# use: replace_substring hello e E RES # sets RES to hEllo
bobshell_substring() {
  # https://freebsdfrau.gitbook.io/serious-shell-programming/string-functions/replace_substringall
  replace_substring_result=
  replace_substring_rest="$1"
  assert_not_empty "$2" 'replace_substring: searched substring must not be empty'
  while :; do
      case "$replace_substring_rest" in *$2*)
          replace_substring_result="$replace_substring_result${replace_substring_rest%%"$2"*}$3"
          replace_substring_rest="${replace_substring_rest#*"$2"}"
          continue
      esac
      break
  done
  replace_substring_result="$replace_substring_result${replace_substring_rest#*"$2"}"
  putvar "${4:-replace_substring_result}" "$replace_substring_result"
}

# fun: bobshell_contains STR PATTERN [LEFTPART [RIGHTPART]]
bobshell_contains() {
	bobshell_require_not_empty "${2:-}" separator should not be empty
	if [ -z "${3:-}" ] && [ -z "${4:-}" ]; then
		case "$1" in
			*"$2"* ) return 0 ;;
			*) return 1 ;;
		esac
	fi
	set -- "$1" "$2" "${3:-}" "${4:-}" "${1#*"$2"}"
	if [ "$1" = "$5" ]; then
		return 1
	fi
	if [ -n "${3:-}" ]; then
		bobshell_putvar "$3" "${1%%"$2"*}"
	fi
	if [ -n "${4:-}" ]; then
		bobshell_putvar "$4" "$5"
	fi

}

bobshell_assing_new_line() {
	bobshell_putvar "$1" '
'
}

bobshell_newline='
'


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
  eval "$1=\"\$2\""
}



# fun bobshell_getvar VARNAME
# use: echo "$(getvar MSG)"
# txt: считывание значения переменной по динамическому имени
bobshell_getvar() {
  eval "printf %s \"\$$1\""
}


bobshell_require_not_empty() {
	if [ -z "${1:-}" ]; then
		shift
		bobshell_die "$@"
	fi
}

bobshell_is_bash() {
	test -n "${BASH_VERSION:-}"
}

bobshell_is_zsh() {
	test -n "${ZSH_VERSION:-}"
}

bobshell_is_ksh() {
	test -n "${KSH_VERSION:-}"
}

bobshell_list_functions() {
	if bobshell_is_bash; then
		compgen -A function
	elif [ -n "${0:-}" ] && [ -f "${0}" ]; then
		sed --regexp-extended 's/^( *function)? *([A-Za-z0_9_]+) *\( *\) *\{ *$/\2/g' "$0"
	fi
}

bobshell_log() {
  printf '%s: %s\n' "$0" "$*" >&2
}


