# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit shelduck.sh.in and run sh ./run build to regenerate it


# see https://github.com/ajdiaz/bashdoc


# fun: shelduck CLIARGS...
shelduck() {
	shelduck_eval "$@"
}



shelduck_usage() {
	printf %s 'Usage: shelduck URL [ALIAS...]'
}



# fun: shelduck_eval CLIARGS...
shelduck_eval() {
	shelduck_eval_script="$(shelduck_print "$@" || bobshell_die 'shelduck_eval: error calling shelduck_print')"
	eval "$shelduck_eval_script"
	unset shelduck_eval_script
}



# fun: shelduck_print CLIARGS...
shelduck_print() {
	# set starting parameters
	shelduck_url_history=
	shelduck_alias_strategy="${SHELDUCK_ALIAS_STRATEGY:-wrap}"
	
	# delegate
	shelduck_print_internal "${SHELDUCK_BASE_URL:-}" "$@"
}




# fun: shelduck_print_internal BASEURL CLIARGS...
# env: shelduck_print_url_history
# txt: parse cli and delegate to shelduck_print_tree
shelduck_print_internal() {
	# todo normal cli

	# 
	shelduck_print_internal_absurl=$(bobshell_resolve_url "$2" "$1")
	shift 2

	shelduck_print_tree "$shelduck_print_internal_absurl" "$@"
	unset shelduck_print_internal_absurl
}


# fun: shelduck_print_tree URL [ALIAS...]
# txt: print rewrite, customization for this script and all dependencies recursively
shelduck_print_tree() {

	# resolve abs url
	shelduck_print_tree_absurl="$1"
	shift 

	# base url
	shelduck_print_tree_base_url=$(bobshell_base_url "$shelduck_print_tree_absurl")

	# load script
	shelduck_print_tree_orig_script=$(shelduck_print_original "$shelduck_print_tree_absurl" "$@")

	
	# script was not already been handled, handle it
	if ! bobshell_contains "$shelduck_url_history" "$shelduck_print_tree_absurl"; then

		# shelduck_print_dependencies is recursive call
		# save to local array
		set -- "$shelduck_print_tree_absurl" "$shelduck_print_tree_base_url" "$shelduck_print_tree_orig_script" "$@"
		
		# print dependencis (calls shelduck_print_tree recursively through shelduck_print_internal)
		shelduck_alias_strategy=wrap
		shelduck_print_dependencies "$shelduck_print_tree_base_url" "$shelduck_print_tree_orig_script"
	
		# restore local variables after recursive call
		shelduck_print_tree_absurl="$1"
		shelduck_print_tree_base_url="$2"
		shelduck_print_tree_orig_script="$3"
		shift 3

		# print (rewritten) script
		shelduck_print_rewrite "$shelduck_print_tree_orig_script" "$shelduck_print_tree_absurl" "$@"

		# mark url as handled
		shelduck_url_history="$shelduck_url_history $shelduck_print_tree_absurl"
	fi

	shelduck_print_customize "$shelduck_print_tree_orig_script" "$shelduck_print_tree_absurl" "$@"


	unset shelduck_print_tree_absurl shelduck_print_tree_base_url shelduck_print_tree_orig_script
}


# fun: shelduck_print_dependencies BASEURL ORIGSCRIPT
# txt: supports recursion
shelduck_print_dependencies() {
	# grep for shelduck commands and save to $1
	shelduck_print_dependencies_lines=$(printf %s "$2" | sed --silent --regexp-extended 's/^ *shelduck (.*)$/\1/pg')
	set -- "$1" "$shelduck_print_dependencies_lines"
	unset shelduck_print_dependencies_lines

	shelduck_print_dependencies_part=
	# shellcheck disable=SC2016
	# shellcheck disable=SC2154
	bobshell_for_each_part "$2" "$bobshell_newline" shelduck_print_dependencies_part \
			eval shelduck_print_internal "'$1'" '$shelduck_print_dependencies_part'
	unset newline shelduck_print_dependencies_part
}





# fun: shelduck_print_original ABSURL [ALIAS...]
# txt: prints original script without modification
shelduck_print_original() {
	shelduck_cached_fetch_url "$1"
}




# fun: shelduck_reprint_script ORIGCONTENT ABSURL [ALIAS...]
# txt: rewrite original script (e.g. comment out shelduck import commands)
shelduck_print_rewrite() {
	if [ rewrite = "$shelduck_alias_strategy" ]; then
		bobshell_die "shelduck_alias_strategy: value $shelduck_alias_strategy not supported"
	fi
	# comment out shelduck dependency directive
	printf %s "$1" | sed --regexp-extended 's/^ *(shelduck .*)$/# shelduck import will be handled\n# \1/g'
}




# fun: shelduck_print_customize ORIGCONTENT ABSURL [ALIAS...]
# txt: print script customization (eg aliases) 
shelduck_print_customize() {

	if [ wrap != "$shelduck_alias_strategy" ]; then
		# nothing to do, wrap was the only supported customization
		return
	fi

	# analyze functions (for aliases)
	regex='^ *([A-Za-z0-9_]+) *\( *\) *\{ *$' # match shell function declaration '  function_name  (   )  {  '
	shelduck_print_customize_function_names="$(printf %s "$1" | sed --silent --regexp-extended "s/$regex/\1/p")"
	unset regex
	# todo detect function name collizion and print warning if so
	

	# analyze aliases
	shelduck_print_customize_url="$2"
	shift 2
	for arg in "$@"; do
		# todo assert $arg not empty
		if ! bobshell_split_key_value "$arg" = key value; then
			key="$arg"
			value="$arg"
		fi
		bobshell_require_not_empty "$key"   line "$arg": key   expected not to be empty
		bobshell_require_not_empty "$value" line "$arg": value expected not to be empty
		
		shelduck_print_script_function_name="$(printf %s "$shelduck_print_customize_function_names" | grep -E "^.*$value\$" || true)"
		if [ -n "$shelduck_print_script_function_name" ]; then
			if [ wrap = "$shelduck_alias_strategy" ]; then
				printf '\n\n'
				printf '\n # shelduck: alias for %s (from %s)' "$shelduck_print_script_function_name" "$shelduck_print_customize_url" 
				printf '\n%s() {' "$key"
				printf '\n	%s "$@"' "$shelduck_print_script_function_name"
				printf '\n}'
				printf '\n'
			else
				bobshell_die "shelduck_alias_strategy: value $shelduck_alias_strategy not supported"
			fi
		fi
		unset key value shelduck_print_script_function_name
	done
	unset shelduck_print_customize_function_names shelduck_print_customize_url
}




# fun: shelduck_cached_fetch_url ABSURL
# txt: download dependency given url and save to cache
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
			printf %s/ "${2%/*}"
		fi
		printf %s "$1"
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


bobshell_split_key_value() {
	bobshell_require_not_empty "${2:-}" separator should not be empty
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



# fun: shelduck_for_each_line STR SEPARATOR VAR COMMAND
# txt: supports recursion
bobshell_for_each_part() {
	while [ -n "$1" ]; do
		if ! bobshell_split_key_value \
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



bobshell_contains() {
	printf %s "$1" | grep --silent -- "$2"
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
  eval "$1='$2'"
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


