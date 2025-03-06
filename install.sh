#!/bin/sh
set -eu
# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit install.sh.in and run sh ./run build to regenerate it

# shelduck: source for file:///home/user/box/workspace/shelduck/install.sh.in


# shelduck_src
# env: PREFIX?
#      DESTDIR
install_shelduck() {
	SHELDUCK_INSTALL_NAME=shelduck
	bobshell_scope_mirror SHELDUCK_INSTALL_ BOBSHELL_INSTALL_
	bobshell_install_init
	bobshell_scope_mirror BOBSHELL_INSTALL_ SHELDUCK_INSTALL_



	
	# install
	: "${SHELDUCK_LIBRARY_URL:=https://raw.githubusercontent.com/legeyda/shelduck/refs/heads/main/shelduck.sh}"
	bobshell_install_put_data "$SHELDUCK_LIBRARY_URL" shelduck.sh


	: "${SHELDUCK_LIBRARY_PATH:=$SHELDUCK_INSTALL_DATADIR/$SHELDUCK_INSTALL_NAME/shelduck.sh}"
	bobshell_install_put_executable stdin: "$SHELDUCK_INSTALL_NAME" <<eof
#!/bin/sh
set -eu
if [ import = "\${1:-}" ]; then
	shift
	printf 'import subcommand not available when run from installed script %s\n' "\$0"
	printf "Instead source library:\n"
	printf '. "%s"\n' '$SHELDUCK_LIBRARY_PATH'
	printf 'shelduck import'
	printf ' %s' "\$@"
	exit 1
fi
. '$SHELDUCK_LIBRARY_PATH'
shelduck "\$@"
eof

	bobshell_install_put_executable stdin: "${SHELDUCK_INSTALL_NAME}_run" <<eof
#!/bin/sh
set -eu
. '$SHELDUCK_LIBRARY_PATH'
shelduck_run "\$@"
eof

	#
	if command_available shelduck; then
		log 'shelduck_resolve was successfully installed to %s, which seems to be already in the PATH' "$SHELDUCK_INSTALL_BINDIR"
		return
	fi

	log "adding $SHELDUCK_INSTALL_BINDIR to path"

	printf '\nPATH="%s:$PATH"' "$SHELDUCK_INSTALL_BINDIR" >> "$SHELDUCK_INSTALL_DESTDIR$BOBSHELL_INSTALL_PROFILE"

}


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh

# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# STRING MANUPULATION





# use: bobshell_starts_with hello he && echo "$rest" # prints llo
bobshell_starts_with() {
	bobshell_starts_with_str="$1"
	shift
	while bobshell_isset_1 "$@"; do
		case "$bobshell_starts_with_str" in
			("$1"*) 
				unset bobshell_starts_with_str			
				return 0
		esac
		shift
	done
	unset bobshell_starts_with_str
	return 1
}

# use: bobshell_starts_with hello he rest && echo "$rest" # prints llo
bobshell_remove_prefix() {
	if [ -z "$2" ]; then
		return 0
	fi
	set -- "$1" "$2" "$3" "${1#"$2"}"
	if [ "$1" = "$4" ]; then
		return 1
	fi
	if [ -n "$3" ]; then
		bobshell_putvar "$3" "$4"
	fi	
}

# use: bobshell_starts_with hello he rest && echo "$rest" # prints llo
bobshell_ends_with() {
	bobshell_isset_3 "$@" && bobshell_die "bobshell_ends_with takes 2 arguments, 3 given, did you mean bobshell_remove_suffix?" || true
	case "$1" in
		(*"$2") return 0
	esac
	return 1
}

bobshell_remove_suffix() {
	if [ -z "$2" ]; then
		return 0
	fi
	set -- "$1" "$2" "$3" "${1%"$2"}"
	if [ "$1" = "$4" ]; then
		return 1
	fi
	if [ -n "$3" ]; then
		bobshell_putvar "$3" "$4"
	fi
}


# fun: bobshell_contains STR SUBSTR
bobshell_contains() {
	case "$1" in
		(*"$2"*) return 0
	esac
	return 1
}


# fun: bobshell_split_first STR SUBSTR [PREFIX [SUFFIX]]
bobshell_split_first() {
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

# fun: bobshell_split_first STR SUBSTR [PREFIX [SUFFIX]]
bobshell_split_last() {
	set -- "$1" "$2" "${3:-}" "${4:-}" "${1%"$2"*}"
	if [ "$1" = "$5" ]; then
		return 1
	fi
	if [ -n "${3:-}" ]; then
		bobshell_putvar "$3" "$5"
	fi
	if [ -n "${4:-}" ]; then
		bobshell_putvar "$4" "${1##*"$2"}"
	fi
}


# txt: заменить в $1 все вхождения строки $2 на строку $3
# use: replace_substring hello e E
bobshell_replace() {
  	# https://freebsdfrau.gitbook.io/serious-shell-programming/string-functions/replace_substringall
	bobshell_replace_str="$1"
	while bobshell_split_first "$bobshell_replace_str" "$2" bobshell_replace_left bobshell_replace_str; do
		printf %s%s "$bobshell_replace_left" "$3"
	done
	printf %s "$bobshell_replace_str"
}






# fun: bobshell_substr STR RANGE OUTPUTVAR
bobshell_substr() {
	
	set -- "$1"
	bobshell_substr_result=$(printf %s "$1" | cut -c "$2-$3")
	col2="$(printf 'foo    bar  baz\n' | cut -c 8-12)"

	unset bobshell_substr_result
}



# txt: regex should be in the basic form (https://www.gnu.org/software/grep/manual/html_node/Basic-vs-Extended.html)
#      ^ is implicitly prepended to regexp
#      https://stackoverflow.com/questions/35693980/test-for-regex-in-string-with-a-posix-shell#comment86337738_35694108
bobshell_basic_regex_match() {
	bobshell_is_regex_match_amount=$(expr "$1" : "$2")
	test "$bobshell_is_regex_match_amount" = "${#1}"
}

bobshell_extended_regex_match() {
	printf %s "$1" | grep --silent --extended-regex "$2"
}

# fun: shelduck_for_each_line STR SEPARATOR VAR COMMAND
# txt: supports recursion
bobshell_for_each_part() {
	while [ -n "$1" ]; do
		if ! bobshell_split_first \
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




bobshell_assing_new_line() {
	bobshell_putvar "$1" '
'
}

bobshell_newline='
'


bobshell_quote() {
	bobshell_quote_separator=''
	for bobshell_quote_arg in "$@"; do
		printf %s "$bobshell_quote_separator"
		if bobshell_basic_regex_match "$bobshell_quote_arg" '[A-Za-z0-9_/\-\=]\+'; then
			printf %s "$bobshell_quote_arg"
		else
			bobshell_quote_arg=$(bobshell_replace "$bobshell_quote_arg" "'" "'"'"'"'"'"'"'")
			printf "'%s'" "$bobshell_quote_arg"
		fi
		bobshell_quote_separator=' '
	done
	unset bobshell_quote_arg
}


# fun: bobshell_join SEPARATOR [ITEM...]
bobshell_join() {
	bobshell_join_separator="$1"
	shift
	for bobshell_join_item in "$@"; do
		printf %s "$bobshell_join_item"
		break
	done
	shift
	for bobshell_join_item in "$@"; do
		printf %s "$bobshell_join_separator"
		printf %s "$bobshell_join_item"
	done
}



bobshell_strip_left() {
	bobshell_strip_left_value="$1"
	while true; do
		case "$bobshell_strip_left_value" in 
			([[:space:]]*)
				bobshell_strip_left_value="${bobshell_strip_left_value#?}" ;;
			(*) break ;;
		esac
	done
	printf %s "$bobshell_strip_left_value"
}

bobshell_strip_right() {
	bobshell_strip_right_value="$1"
	while true; do
		case "$bobshell_strip_right_value" in 
			(*[[:space:]])
				bobshell_strip_right_value="${bobshell_strip_right_value%?}" ;;
			(*) break ;;
		esac
	done
	printf %s "$bobshell_strip_right_value"
}

bobshell_strip() {
	bobshell_strip_value=$(bobshell_strip_left "$1")
	bobshell_strip_right "$bobshell_strip_value"
}

bobshell_upper_case() {
	printf %s "$*" | awk 'BEGIN { getline; print toupper($0) }'
}

bobshell_lower_case() {
	printf %s "$*" | awk 'BEGIN { getline; print tolower($0) }'
}

# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/require.sh




bobshell_require_isset_1() {
	if ! bobshell_isset_1 "$@"; then
		bobshell_die '%s: ' "${*:-argument 1 required to be set}"
	fi
}

bobshell_require_isset_2() {
	if ! bobshell_isset_2 "$@"; then
		bobshell_die '%s: ' "${*:-argument 2 required to be set}"
	fi	
}

bobshell_require_isset_3() {
	if ! bobshell_isset_3 "$@"; then
		bobshell_die '%s: ' "${*:-argument 3 required to be set}"
	fi	
}

bobshell_require_isset() {
	if ! bobshell_isset "$1"; then
		bobshell_die '%s: ' "${*:-variable $1 required to be set}"
	fi
}

bobshell_require_file_exists() {
	if [ ! -e "$1" ]; then
		printf '%s: no such file\n' "$1"
		return 1
	fi
}

bobshell_require_not_empty() {
	if [ -z "$1" ]; then
		bobshell_die '%s: ' "${*:value required not to be empty}"
	fi
}


bobshell_die() {
  # https://github.com/biox/pa/blob/main/pa
  printf '%s: %s.\n' "$(basename "$0")" "${*:-error}" >&2
  exit 1
}


# use isset OPTVARNAME
bobshell_isset() {
	eval "test \"\${$1+defined}\" = defined"
}

#  
bobshell_isset_1() {
	eval "test \"\${1+defined}\" = defined"
}

bobshell_isset_2() {
	eval "test \"\${2+defined}\" = defined"
}

bobshell_isset_3() {
	eval "test \"\${3+defined}\" = defined"
}

bobshell_command_available() {
	command -v "$1" > /dev/null
}

# fun: bobshell_putvar VARNAME NEWVARVALUE
# txt: установка значения переменной по динамическому имени
bobshell_putvar() {
  eval "$1=\"\$2\""
}



# fun bobshell_getvar VARNAME [DEFAULTVALUE]
# use: echo "$(getvar MSG)"
# txt: считывание значения переменной по динамическому имени
bobshell_getvar() {
	if bobshell_isset "$1"; then
  		eval "printf %s \"\$$1\""
	elif bobshell_isset_2 "$@"; then
		printf %s "$2"
	else
		bobshell_errcho "bobshell_getvar: $1: parameter not set"
		return 1
	fi
}


bobshell_require_not_empty() {
	if [ -z "${1:-}" ]; then
		shift
		bobshell_die "$@"
	fi
}

bobshell_require_empty() {
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
	bobshell_log_message="$*"
	printf '%s: %s\n' "$0" "$bobshell_log_message" >&2
	unset bobshell_log_message
}

bobshell_rename_var() {
	if [ "$1" = "$2" ]; then
		return
	fi
	eval "$2=\$$1"
	unset "$1"
}

bobshell_vars() {
	bobshell_vars_list=$(set | sed -n 's/^\([A-Za-z_][A-Za-z_0-9]*\)=.*$/\1/pg' | sort -u)
	for bobshell_vars_item in $bobshell_vars_list; do
		if bobshell_isset "$bobshell_vars_item"; then
			printf '%s ' "$bobshell_vars_item"
		fi
	done
	unset bobshell_vars_list
}

# bobshell_not_empty "$@"
bobshell_not_empty() {
	test set = "${1+set}" 
}

#bobshell_map

# fun: bobshell_foreach ITEM... -- COMMAND [ARG...]
# bobshell_foreach() {
# 	bobshell_foreach_items=
# 	bobshell_foreach_command=
# 	while bobshell_not_empty "$@"; do
# 		if [ '--' = "$1" ]; then
# 			shift
# 			set -- "$@"
# 			break
# 		fi
# 		bobshell_foreach_item=$(bobshell_quote "$1")
# 		bobshell_foreach_items="$bobshell_foreach_items $1"
# 		shift
# 	done

# 	bobshell_require_not_empty "$bobshell_foreach_command" "bobshell_foreach: command not set"

# 	for bobshell_foreach_item in $bobshell_foreach_items; do
# 		"$@" "$bobshell_foreach_item"
# 	done
# 	unset bobshell_foreach_item

# 	unset bobshell_foreach_items bobshell_foreach_command
# }

bobshell_error() {
	bobshell_errcho "$@"
	return 1
}

bobshell_errcho() {
	printf '%s\n' "$*" >&2
}

bobshell_printf_stderr() {
	printf '%s\n' "$*" >&2
}

bobshell_subshell() {
	( "$@" )
}

bobshell_last_arg() {
	bobshell_require_isset_1 'bobshell_last_arg: at least one positional argument expected'
	while bobshell_isset_2 "$@"; do
		shift
	done
	printf %s "$1"
}




 # shelduck: alias for bobshell_die (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh)
die() {
	bobshell_die "$@"
}



 # shelduck: alias for bobshell_command_available (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh)
command_available() {
	bobshell_command_available "$@"
}



 # shelduck: alias for bobshell_log (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh)
log() {
	bobshell_log "$@"
}

# shellcheck disable=SC2148





bobshell_fetch_url() {
	if bobshell_remove_prefix "$1" 'file://' bobshell_fetch_url_path; then
		# shellcheck disable=SC2154
		# bobshell_remove_prefix sets variable bobshell_fetch_url_path indirectly
		cat "$bobshell_fetch_url_path"
		unset bobshell_fetch_url_path
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


# fun: bobshell_resolve_url URL [BASEURL]
bobshell_resolve_url() {
	# todo by default BASEURL is $(realpath "$(pwd)")
	if bobshell_starts_with "$1" /; then
		bobshell_resolve_url_path=$(realpath "$1")
		printf 'file://%s' "$bobshell_resolve_url_path"
	elif bobshell_remove_prefix "$1" file:// bobshell_resolve_url_path; then
		bobshell_resolve_url_path=$(realpath "$bobshell_resolve_url_path")
		printf 'file://%s' "$bobshell_resolve_url_path"
	elif bobshell_starts_with "$1" http:// \
	  || bobshell_starts_with "$1" https:// \
	  || bobshell_starts_with "$1" ftp:// \
	  || bobshell_starts_with "$1" ftps:// \
			; then
		printf %s "$1"
	else
		if bobshell_isset_2 "$@"; then
			bobshell_resolve_url_base="$2"	
			while bobshell_remove_suffix "$bobshell_resolve_url_base" / bobshell_resolve_url_base; do
				true
			done
		else
			bobshell_resolve_url_base=$(pwd)
		fi

		bobshell_resolve_url_value="$1"
		while bobshell_remove_prefix "$bobshell_resolve_url_value" './' bobshell_resolve_url_value; do
			true
		done


		while bobshell_remove_prefix "$bobshell_resolve_url_value" '../' bobshell_resolve_url_value; do
			if ! bobshell_split_last "$bobshell_resolve_url_base" / bobshell_resolve_url_base; then
				bobshell_die "bobshell_resolve_url: base=$bobshell_resolve_url_base, url=$bobshell_resolve_url_value"
			fi
		done

		printf '%s/%s' "$bobshell_resolve_url_base" "$bobshell_resolve_url_value"
		unset bobshell_resolve_url_base bobshell_resolve_url_value
	fi
}

bobshell_fetch_url_with_curl() {
	curl --fail --silent --show-error --location "$1"
}

bobshell_fetch_url_with_wget() {
	wget --no-verbose --output-document -
}




 # shelduck: alias for bobshell_fetch_url (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/url.sh)
fetch_url() {
	bobshell_fetch_url "$@"
}

# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/install.sh


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/util.sh




# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/git.sh


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/ssh.sh

# fun: scope bobshell command [arg...]
# use: bobshell_shauth git clone blabl
# use: notrace echo hello
# txt: выполнить команду, скрывая трассировку от set -x
bobshell_notrace() {
	{ "$@"; } 2> /dev/null
}


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator.sh






# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/is_file.sh




# fun: bobshell_is_file LOCATOR [FILEPATHVAR]
bobshell_locator_is_file() {
	if bobshell_starts_with "$1" /; then
		if [ -n "${2:-}" ]; then
			bobshell_putvar "$2" "$1"
		fi
	else
		bobshell_remove_prefix "$1" file: "${2:-}"
	fi
}


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/parse.sh





bobshell_locator_parse() {
	if bobshell_starts_with "$1" /; then
		bobshell_locator_parse_type='file'
		bobshell_locator_parse_ref="$1"
	elif ! bobshell_split_first "$1" : bobshell_locator_parse_type bobshell_locator_parse_ref; then
		return 1
	fi

	case "$bobshell_locator_parse_type" in
		(val | var | eval | stdin | stdout | file | url)
			true ;;
		(http | https | ftp | ftps) 
			bobshell_locator_parse_type=url
			bobshell_locator_parse_ref="$1"
			;;
		(*)
			return 1
	esac
	
	if [ -n "${2:-}" ]; then
		bobshell_copy_val_to_var "$bobshell_locator_parse_type" "$2"
	fi
	if [ -n "${3:-}" ]; then
		bobshell_copy_val_to_var "$bobshell_locator_parse_ref" "$3"
	fi
}



# deprecated see ./locator/parse.sh
bobshell_parse_locator() {
	bobshell_locator_parse "$1" "$2" "${3:-bobshell_parse_locator_type}" "${3:-bobshell_parse_locator_ref}"
}



# fun: bobshell_copy SOURCE DESTINATION
bobshell_copy() {
	bobshell_parse_locator "$1" bobshell_copy_source_type      bobshell_copy_source_ref
	bobshell_parse_locator "$2" bobshell_copy_destination_type bobshell_copy_destination_ref


	bobshell_copy_command="bobshell_copy_${bobshell_copy_source_type}_to_${bobshell_copy_destination_type}"
	if ! bobshell_command_available "$bobshell_copy_command"; then
		bobshell_die "bobshell_copy: unsupported copy $bobshell_copy_source_type to $bobshell_copy_destination_type"
	fi

	"$bobshell_copy_command" "$bobshell_copy_source_ref" "$bobshell_copy_destination_ref"
	
	unset bobshell_copy_source_type bobshell_copy_source_ref
	unset bobshell_copy_destination_type bobshell_copy_destination_ref
}


bobshell_copy_to_val()           { bobshell_die 'cannot write to val resource'; }
bobshell_copy_eval()             { bobshell_die 'eval resource cannot be destination'; }
bobshell_copy_to_stdin()         { bobshell_die 'cannot write to stdin resource'; }
bobshell_copy_stdout()           { bobshell_die 'cannot read from stdout resource'; }
bobshell_copy_to_url()           { bobshell_die 'cannot write to stdin resource'; }



bobshell_copy_val_to_val()       { test "$1" != "$2" && bobshell_copy_to_val; }
bobshell_copy_val_to_var()       { eval "$2='$1'"; }
bobshell_copy_val_to_eval()      { eval "$1"; }
bobshell_copy_val_to_stdin()     { bobshell_copy_to_stdin; }
bobshell_copy_val_to_stdout()    { printf %s "$1"; }
bobshell_copy_val_to_file()      { printf %s "$1" > "$2"; }
bobshell_copy_val_to_url()       { bobshell_copy_to_url; }



bobshell_copy_var_to_val()       { bobshell_copy_to_val; }
bobshell_copy_var_to_var()       { test "$1" != "$2" && eval "$2=\"\$$1\""; }
bobshell_copy_var_to_eval()      { eval "bobshell_copy_var_to_eval \"\$$1\""; }
bobshell_copy_var_to_stdin()     { bobshell_copy_to_stdin; }
bobshell_copy_var_to_stdout()    { eval "printf %s \"\$$1\""; }
bobshell_copy_var_to_file()      { eval "printf %s \"\$$1\"" > "$2"; }
bobshell_copy_var_to_url()       { bobshell_copy_to_url; }



bobshell_copy_eval_to_val()      { bobshell_copy_eval; }
bobshell_copy_eval_to_var()      { bobshell_copy_eval; }
bobshell_copy_eval_to_eval()     { bobshell_copy_eval; }
bobshell_copy_eval_to_stdin()    { bobshell_copy_eval; }
bobshell_copy_eval_to_stdout()   { bobshell_copy_eval; }
bobshell_copy_eval_to_file()     { bobshell_copy_eval; }
bobshell_copy_eval_to_url()      { bobshell_copy_eval; }



bobshell_copy_stdin_to_val()     { bobshell_copy_to_val; }
bobshell_copy_stdin_to_var()     { eval "$2=\$(cat)"; }
bobshell_copy_stdin_to_eval()    {
	bobshell_copy_stdin_to_var "$1" bobshell_copy_stdin_to_eval_data
	bobshell_copy_var_to_eval bobshell_copy_stdin_to_eval_data ''
	unset bobshell_copy_stdin_to_eval_data; 
}
bobshell_copy_stdin_to_stdin()   { bobshell_copy_to_stdin; }
bobshell_copy_stdin_to_stdout()  { cat; }
bobshell_copy_stdin_to_file()    { cat > "$2"; }
bobshell_copy_stdin_to_url()     { bobshell_copy_to_url; }



bobshell_copy_stdout_to_val()    { bobshell_copy_stdout; }
bobshell_copy_stdout_to_var()    { bobshell_copy_stdout; }
bobshell_copy_stdout_to_eval()   { bobshell_copy_stdout; }
bobshell_copy_stdout_to_stdin()  { bobshell_copy_stdout; }
bobshell_copy_stdout_to_stdout() { bobshell_copy_stdout; }
bobshell_copy_stdout_to_file()   { bobshell_copy_stdout; }
bobshell_copy_stdout_to_url()    { bobshell_copy_to_url; }



bobshell_copy_file_to_val()      { bobshell_copy_to_val; }
bobshell_copy_file_to_var()      { eval "$2=\$(cat '$1')"; }
bobshell_copy_file_to_eval()     {
	bobshell_copy_file_to_var "$1" bobshell_copy_file_to_eval_data
	bobshell_copy_var_to_eval bobshell_copy_file_to_eval_data ''
	unset bobshell_copy_file_to_eval_data; 
}
bobshell_copy_file_to_stdin()    { bobshell_copy_to_stdin; }
bobshell_copy_file_to_stdout()   { cat "$1"; }
bobshell_copy_file_to_file()     { test "$1" != "$2" && { mkdir -p "$(dirname "$2")" && rm -rf "$2" && cp -f "$1" "$2";}; }
bobshell_copy_file_to_url()      { bobshell_copy_to_url; }



bobshell_copy_url_to_val()       { bobshell_copy_to_val; }
bobshell_copy_url_to_var()       { bobshell_fetch_url "$1" | bobshell_copy_stdin_to_var '' "$2"; }
bobshell_copy_url_to_eval()      { bobshell_fetch_url "$1" | bobshell_copy_stdin_to_var '' "$2"; }
bobshell_copy_url_to_stdin()     { bobshell_copy_to_stdin; }
bobshell_copy_url_to_stdout()    { bobshell_fetch_url "$1"; }
bobshell_copy_url_to_file()      { bobshell_fetch_url "$1" | bobshell_copy_stdin_to_file '' "$2"; }
bobshell_copy_url_to_url()       { bobshell_copy_to_url; }



# fun: bobshell_locator_as_file LOCATOR
bobshell_locator_as_file() {
	if bobshell_starts_with "$1" "file:" bobshell_locator_as_file_ref; then
		copy_resource var:bobshell_locator_as_file_ref "$2"
	else
		# shellcheck disable=SC2034
		bobshell_locator_as_file_result="$(mktemp)"
		copy_resource "$1" "file:$bobshell_locator_as_file_result"
		copy_resource var:bobshell_locator_as_file_result "$2"
		unset bobshell_locator_as_file_result
	fi
	unset bobshell_locator_as_file_ref
}

bobshell_locator_is_stdin() {
	bobshell_remove_prefix "$1" stdin: "${2:-}"
}

bobshell_locator_is_stdout() {
	bobshell_remove_prefix "$1" stdout: "${2:-}"
}

# fun: bobshell_resource_is_appendable LOCATOR
bobshell_locator_is_appendable() {
	bobshell_starts_with "$1" var: stdout: file: /
}


bobshell_locator_is_remote() {
	bobshell_remove_prefix "$1" http:// "${2:-}" \
	  || bobshell_remove_prefix "$1" https:// "${2:-}" \
	  || bobshell_remove_prefix "$1" ftp:// "${2:-}"\
	  || bobshell_remove_prefix "$1" ftps:// "${2:-}"
}

bobshell_move() {
	bobshell_parse_locator "$1" bobshell_move_source_type      bobshell_move_source_ref
	bobshell_parse_locator "$2" bobshell_move_destination_type bobshell_move_destination_ref


	bobshell_move_command="bobshell_move_${bobshell_move_source_type}_to_${bobshell_move_destination_type}"
	if bobshell_command_available "$bobshell_move_command"; then
		"$bobshell_move_command" "$bobshell_move_source_ref" "$bobshell_move_destination_ref"
		unset bobshell_move_source_type bobshell_move_source_ref
		unset bobshell_move_destination_type bobshell_move_destination_ref
		return
	fi
	
	bobshell_copy "$1" "$2"
	bobshell_delete "$1"
}

bobshell_delete_file() { rm -f "$1"; }
bobshell_delete_var() { unset "$1"; }


bobshell_move_file_to_file() {
	bobshell_die not implemented
}

bobshell_delete() {
	bobshell_parse_locator "$1" bobshell_delete_type bobshell_delete_ref

	bobshell_delete_command="bobshell_delete_${bobshell_delete_type}"
	if ! bobshell_command_available "$bobshell_delete_command"; then
		bobshell_die "bobshell_delete: unsupported resource of type: $bobshell_delete_type"
	fi

	"$bobshell_delete_command" "$bobshell_delete_ref"
	return
}

bobshell_append() {
	bobshell_die not implemented
}




bobshell_append_to_val()           { bobshell_die 'cannot append to val resource'; }
bobshell_append_eval()             { bobshell_die 'eval resource cannot be destination'; }
bobshell_append_to_stdin()         { bobshell_die 'cannot append to stdin resource'; }
bobshell_append_stdout()           { bobshell_die 'cannot read from stdout resource'; }
bobshell_append_to_url()           { bobshell_die 'cannot append to stdin resource'; }



bobshell_append_val_to_val()       { test "$1" != "$2" && bobshell_append_to_val; }
bobshell_append_val_to_var()       { eval "$2='$1'"; }
bobshell_append_val_to_eval()      { eval "$1"; }
bobshell_append_val_to_stdin()     { bobshell_append_to_stdin; }
bobshell_append_val_to_stdout()    { printf %s "$1"; }
bobshell_append_val_to_file()      { printf %s "$1" > "$2"; }
bobshell_append_val_to_url()       { bobshell_append_to_url; }



bobshell_append_var_to_val()       { bobshell_append_to_val; }
bobshell_append_var_to_var()       { test "$1" != "$2" && eval "$2=\${$1}"; }
bobshell_append_var_to_eval()      { eval "bobshell_append_var_to_eval \"\$$1\""; }
bobshell_append_var_to_stdin()     { bobshell_append_to_stdin; }
bobshell_append_var_to_stdout()    { eval "printf %s \"\$$1\""; }
bobshell_append_var_to_file()      { eval "printf %s \"\$$1\"" > "$2"; }
bobshell_append_var_to_url()       { bobshell_append_to_url; }



bobshell_append_eval_to_val()      { bobshell_append_eval; }
bobshell_append_eval_to_var()      { bobshell_append_eval; }
bobshell_append_eval_to_eval()     { bobshell_append_eval; }
bobshell_append_eval_to_stdin()    { bobshell_append_eval; }
bobshell_append_eval_to_stdout()   { bobshell_append_eval; }
bobshell_append_eval_to_file()     { bobshell_append_eval; }
bobshell_append_eval_to_url()      { bobshell_append_eval; }



bobshell_append_stdin_to_val()     { bobshell_append_to_val; }
bobshell_append_stdin_to_var()     { eval "$2=\$(cat)"; }
bobshell_append_stdin_to_eval()    {
	bobshell_append_stdin_to_var "$1" bobshell_append_stdin_to_eval_data
	bobshell_append_var_to_eval bobshell_append_stdin_to_eval_data ''
	unset bobshell_append_stdin_to_eval_data; 
}
bobshell_append_stdin_to_stdin()   { bobshell_append_to_stdin; }
bobshell_append_stdin_to_stdout()  { cat; }
bobshell_append_stdin_to_file()    { cat > "$2"; }
bobshell_append_stdin_to_url()     { bobshell_append_to_url; }



bobshell_append_stdout_to_val()    { bobshell_append_stdout; }
bobshell_append_stdout_to_var()    { bobshell_append_stdout; }
bobshell_append_stdout_to_eval()   { bobshell_append_stdout; }
bobshell_append_stdout_to_stdin()  { bobshell_append_stdout; }
bobshell_append_stdout_to_stdout() { bobshell_append_stdout; }
bobshell_append_stdout_to_file()   { bobshell_append_stdout; }
bobshell_append_stdout_to_url()    { bobshell_append_to_url; }



bobshell_append_file_to_val()      { bobshell_append_to_val; }
bobshell_append_file_to_var()      { eval "$2=\$(cat '$1')"; }
bobshell_append_file_to_eval()     {
	bobshell_append_file_to_var "$1" bobshell_append_file_to_eval_data
	bobshell_append_var_to_eval bobshell_append_file_to_eval_data ''
	unset bobshell_append_file_to_eval_data; 
}
bobshell_append_file_to_stdin()    { bobshell_append_to_stdin; }
bobshell_append_file_to_stdout()   { cat "$1"; }
bobshell_append_file_to_file()     { test "$1" != "$2" && { mkdir -p "$(dirname "$2")" && rm -rf "$2" && cp "$1" "$2";}; }
bobshell_append_file_to_url()      { bobshell_append_to_url; }



bobshell_append_url_to_val()       { bobshell_append_to_val; }
bobshell_append_url_to_var()       { bobshell_fetch_url "$1" | bobshell_append_stdin_to_var '' "$2"; }
bobshell_append_url_to_eval()      { bobshell_fetch_url "$1" | bobshell_append_stdin_to_var '' "$2"; }
bobshell_append_url_to_stdin()     { bobshell_append_to_stdin; }
bobshell_append_url_to_stdout()    { bobshell_fetch_url "$1"; }
bobshell_append_url_to_file()      { bobshell_fetch_url "$1" | bobshell_append_stdin_to_file '' "$2"; }
bobshell_append_url_to_url()       { bobshell_append_to_url; }







# use: bobshell_ssh user@host echo hello
bobshell_ssh() {
	sleep "${BOBSHELL_SSH_DELAY:-0}"
	bobshell_ssh_auth ssh "$@"
}



bobshell_scp() {
	sleep "${BOBSHELL_SSH_DELAY:-0}"
	bobshell_ssh_auth scp "$@"
}



bobshell_ssh_auth() {
		
	if [ -n "${BOBSHELL_SSH_PORT:-}" ]; then
		bobshell_sshauth_executable="$1"
		shift
		set -- "$bobshell_sshauth_executable" -p "$BOBSHELL_SSH_PORT" "$@"
		unset bobshell_sshauth_executable
	fi

	# ssh-keyscan -H host "$(dig +short host)""
	if [ -z "${BOBSHELL_SSH_KNOWN_HOSTS_FILE:-}" ] && [ -n "${BOBSHELL_SSH_KNOWN_HOSTS:-}" ]; then
		BOBSHELL_SSH_KNOWN_HOSTS_FILE="$(mktemp)"
		printf '%s\n' "$BOBSHELL_SSH_KNOWN_HOSTS" > "$BOBSHELL_SSH_KNOWN_HOSTS_FILE"
	fi
	if [ -n "${BOBSHELL_SSH_KNOWN_HOSTS_FILE:-}" ]; then
		bobshell_sshauth_executable="$1"
		shift
		set -- "$bobshell_sshauth_executable" -o "UserKnownHostsFile='$BOBSHELL_SSH_KNOWN_HOSTS_FILE'" "$@"
		unset bobshell_sshauth_executable
	fi
	if [ -n "${BOBSHELL_SSH_USER:-}" ]; then
		bobshell_sshauth_executable="$1"
		shift
		set -- "$bobshell_sshauth_executable" -o "User='$BOBSHELL_SSH_USER'" "$@"
		unset bobshell_sshauth_executable
	fi
	if bobshell_isset BOBSHELL_SSH_CONNECT_TIMEOUT; then
		_bobshell_ssh_auth__executable="$1"
		shift
		set -- "$_bobshell_ssh_auth__executable" -o "ConnectTimeout=$BOBSHELL_SSH_CONNECT_TIMEOUT" "$@"
		unset _bobshell_ssh_auth__executable
	fi
	if bobshell_isset BOBSHELL_SSH_CONNECTION_ATTEMPTS; then
		_bobshell_ssh_auth__executable="$1"
		shift
		set -- "$_bobshell_ssh_auth__executable" -o "ConnectionAttempts=$BOBSHELL_SSH_CONNECTION_ATTEMPTS" "$@"
		unset _bobshell_ssh_auth__executable
	fi

	if [ -n "${BOBSHELL_SSH_IDENTITY:-}" ]; then
		if [ "${BOBSHELL_SSH_USE_AGENT:-true}" == 'true' ]; then
			if [ -z "${SSH_AGENT_PID:-}" ]; then
				bobshell_eval_output ssh-agent >&2
				# todo copy_resource 'stdout:ssh-agent' eval:
			fi
			bobshell_notrace printf '%s\n' "$BOBSHELL_SSH_IDENTITY" | ssh-add -q -t 5 -
		elif [ -z "${BOBSHELL_SSH_IDENTITY_FILE:-}" ]; then
			BOBSHELL_SSH_IDENTITY_FILE="$(mktemp)"
			chmod 600 "$BOBSHELL_SSH_IDENTITY_FILE" # ???
			# shellcheck disable=SC2016
			bobshell_notrace printf '%s\n' "$BOBSHELL_SSH_IDENTITY" > "$BOBSHELL_SSH_IDENTITY_FILE"
		fi
	fi
	
	if [ -n "${BOBSHELL_SSH_IDENTITY_FILE:-}" ]; then
		bobshell_sshauth_executable="$1"
		shift
		set -- "$bobshell_sshauth_executable" -i "$BOBSHELL_SSH_IDENTITY_FILE" "$@"
		unset bobshell_sshauth_executable
	fi

	bobshell_maybe_sshpass "$@"
}



bobshell_maybe_sshpass() {
	if [ -n "${BOBSHELL_SSH_PASSWORD:-}" ] && bobshell_command_available sshpass; then
		set -- sshpass "-p$BOBSHELL_SSH_PASSWORD" "$@"
	fi
	"$@"
}


bobshell_ssh_keyscan() {
	for bobshell_ssh_keyscan_host in "$@"; do
		bobshell_ssh_keyscan_addr=$(dig +short "$bobshell_ssh_keyscan_host")
		set -- "$@" "$bobshell_ssh_keyscan_addr"
	done
	unset bobshell_ssh_keyscan_host bobshell_ssh_keyscan_addr
	bobshell_ssh_auth ssh-keyscan "$@"
}



# fun: bobshell_ssh_keygen FILE
bobshell_ssh_keygen() {
	bobshell_ssh_keygen_dir=$(dirname "$1")
	mkdir -p "$bobshell_ssh_keygen_dir"
	rm -f "$1" "$1.pub"
	ssh-keygen -q -t ed25519 -b 2048 -N '' -f "$1"
}



# fun: bobshell_get_private_key FILEPATH LOCATOR
bobshell_copy_private_key() {
	bobshell_copy "file:$1" "$2"
}



# fun: bobshell_get_public_key FILEPATH LOCATOR
bobshell_copy_public_key() {
	bobshell_copy "file:$1.pub" "$2"
}







bobshell_git() {
	bobshell_git_ssh_auth git "$@"
}

# bobshell_git_url_is_ssh() {
# 	bobshell_git_url_is_ssh_protocol=$(bobshell_git_get_url_protocol "$@")
# 	test ssh = "$bobshell_git_url_is_ssh_protocol"
# }

# bobshell_git_get_url_protocol() {
# 	if bobshell_starts_with "$1" 'ssh://'; then
# 		printf ssh
# 		return
# 	elif bobshell_starts_with "$1" 'https://'; then
# 		printf https
# 	elif bobshell_starts_with "$1" 'git@' && bobshell_contains "$1" :; then
# 		printf ssh
# 	fi
# 	bobshell_die 'unable to determine url protocol: %s' "$1"
# }


bobshell_git_ssh_auth() {
	if ! bobshell_isset GIT_SSH_COMMAND; then
		bobshell_git_auth_old_password="${BOBSHELL_SSH_PASSWORD:-}"
		unset BOBSHELL_SSH_PASSWORD
		bobshell_git_auth_command=$(bobshell_ssh_auth bobshell_quote)
		if [ -n "$bobshell_git_auth_command" ]; then
			GIT_SSH_COMMAND="ssh $bobshell_git_auth_command"
		fi
		BOBSHELL_SSH_PASSWORD="$bobshell_git_auth_old_password"
	fi
	if bobshell_isset GIT_SSH_COMMAND; then
		export GIT_SSH_COMMAND
	fi
	bobshell_maybe_sshpass "$@"
}

bobshell_git_version() {
	bobshell_git_version_release=false
	while bobshell_isset_1 "$@"; do
		case "$1" in
			(-r|--release) bobshell_git_version_release=true ;;
			(*) bobshell_die "bobshell_git_version: unexpected argument: $1"
		esac
		shift
	done
	
	if [ true = "$bobshell_git_version_release" ]; then
		if ! bobshell_git_is_clean; then
			bobshell_printf_stderr 'bobshell_git_version: working folder has local modifications'
			return 1
		fi
		unset bobshell_git_version
		if ! bobshell_git_version=$(bobshell_git_version_if_relase 2> /dev/null) || [ -z "$bobshell_git_version" ]; then
			bobshell_printf_stderr 'bobshell_git_version: no git (annotated) tag, which is required'
			return 1
		fi
		if ! bobshell_remove_prefix "$bobshell_git_version" v bobshell_git_version; then
			bobshell_printf_stderr 'bobshell_git_version: wrong tag format: %s' "$bobshell_git_version"
			return 1
		fi
		printf %s "$bobshell_git_version"
		unset bobshell_git_version
	else
		bobshell_git_version_if_not_relase
	fi

}

bobshell_git_version_if_relase() {
	git describe
}

bobshell_git_version_if_not_relase() {
	git describe --abbrev=8 --always --dirty --broken
}

bobshell_git_is_clean() {
	bobshell_git_is_clean_output=$(git status --porcelain)
	test -z "$bobshell_git_is_clean_output"
}

bobshell_git_change_hash() {
	git diff HEAD | git hash-object --stdin
}





bobshell_current_seconds() {
	date +%s
}



# fun: save_output VARIABLE COMMAND [ARG...]
bobshell_save_output() {
	save_output_var="$1"
	shift
	save_output=$("$@")
	bobshell_putvar "$save_output_var" "$save_output"
	unset save_output_var save_output
}



bobshell_eval_output() {
	# stdout:cat
	# stdin:cat
	# todo: copy_resource "stdout:$*" "eval:"
	bobshell_eval_output=$("$@")
	eval "$bobshell_eval_output"
	unset bobshell_eval_output
}


# txt: read -sr 
bobshell_read_secret() {
  # https://github.com/biox/pa/blob/main/pa
  [ -t 0 ] && stty -echo
	read -r "$1"
	[ -t 0 ] &&  stty echo
}



bobshell_run_url() {
	if bobshell_command_available "$1"; then
		"$@"
	elif [ -z "$1" ]; then
		"$@"
	elif bobshell_ends_with "$1" '.git'; then
		bobshell_run_url_git "$@"
	else
		bobshell_die "bobshell_run_url: unrecognized parameters: $(boshell_quote "$@")"
	fi
}

bobshell_run_url_git() {
	bobshell_run_url_git_dir=$(mktemp -d)
	bobshell_git clone "$1" "$bobshell_run_url_git_dir"
	"$bobshell_run_url_git_dir/run" "$@"
}

# txt: выполнить команду, восстановить после неё значения переменных окружения
# use: X=1; Y=2; preserve_environment 'eval' 'X=2, Z=3'; echo "$X, $Y, $Z" # gives 1, 2, 3
bobshell_preserve_env() {
  bobshell_preserve_env_orig=
  # shellcheck disable=SC2016
  bobshell_preserve_env_orig="$(set)"
  "$@"
  eval "$bobshell_preserve_env_orig"
  unset bobshell_preserve_env_orig
}

bobshell_is_root() {
	test 0 = "$(id -u)"
}

bobshell_is_not_root() {
	test 0 != "$(id -u)"
}

bobshell_eval() {
	bobshell_eval_script=
	bobshell_copy "$1" var:bobshell_eval_script
	eval "$bobshell_eval_script"
}



# fun: shelduck_eval_with_args SCRIPT [ARGS...]
shelduck_eval_with_args() {
	shelduck_eval_with_args_script="$1"
	shift
	eval "$shelduck_eval_with_args_script"
}


bobshell_uid() {
	id -u
}

bobshell_gid() {
	id -g
}


bobshell_user_name() {
	printf %s "$USER" # todo
}



bobshell_user_home() {
	printf %s "$HOME" # todo
}

bobshell_get_file_mtime() {

	# LC_TIME=en_US.UTF-8 ls -ld ./pom.xml | sed -n 's/^.* \([A-Z][a-z]\{2\} \+[0-9]\+\).*$/\1/p'
	#LC_TIME=en_US.UTF-8 ls -ld ./pom.xml | sed -n 's/^.* \(\(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec\) \+[0-9]\+ \+\).*$/\1/p'

	LC_TIME=en_US.UTF-8 ls -ld ./pom.xml | sed -n 's/^.* \(\(Jan\|Feb\|Mar\|Apr\|May\|Jun\|Jul\|Aug\|Sep\|Oct\|Nov\|Dec\) \+[1-9]\+ \+[0-9]\+\:[0-9]\+\).*$/\1/p'
	# 

	bobshell_get_file_mtime_dirname=$(dirname "$1")
	bobshell_get_file_mtime_basename=$(basename "$1")
	find "$bobshell_get_file_mtime_dirname" -maxdepth 1 -name "$bobshell_get_file_mtime_basename" -printf "%Ts"
	unset bobshell_get_file_mtime_dirname bobshell_get_file_mtime_basename
}

# bobshell_line_in_file: 
bobshell_line_in_file() {
	true
}






# env: BOBSHELL_INSTALL_NAME
bobshell_install_init() {
	# https://www.gnu.org/prep/standards/html_node/Directory-Variables.html#Directory-Variables
	
	if [ -z "$BOBSHELL_INSTALL_NAME" ] && [ -n "$BOBSHELL_APP_NAME" ]; then
		BOBSHELL_INSTALL_NAME="$BOBSHELL_APP_NAME"
	fi

	: "${BOBSHELL_INSTALL_DESTDIR:=}"
	: "${BOBSHELL_INSTALL_ROOT:=}"
	if [ -n "${BOBSHELL_INSTALL_ROOT:-}" ]; then
		BOBSHELL_INSTALL_ROOT=$(realpath "$BOBSHELL_INSTALL_ROOT")
	fi

	# https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html
	: "${BOBSHELL_INSTALL_SYSTEM_BINDIR=${BOBSHELL_INSTALL_BINDIR-$BOBSHELL_INSTALL_ROOT/opt/bin}}"
	: "${BOBSHELL_INSTALL_SYSTEM_CONFDIR=${BOBSHELL_INSTALL_CONFDIR-$BOBSHELL_INSTALL_ROOT/etc/opt}}"
	: "${BOBSHELL_INSTALL_SYSTEM_DATADIR=${BOBSHELL_INSTALL_DATADIR-$BOBSHELL_INSTALL_ROOT/opt}}"
	: "${BOBSHELL_INSTALL_SYSTEM_LOCALSTATEDIR=${BOBSHELL_INSTALL_LOCALSTATEDIR-$BOBSHELL_INSTALL_ROOT/var/opt}}"
	: "${BOBSHELL_INSTALL_SYSTEM_CACHEDIR=${BOBSHELL_INSTALL_CACHEDIR-$BOBSHELL_INSTALL_ROOT/var/cache/opt}}"
	: "${BOBSHELL_INSTALL_SYSTEM_SYSTEMDDIR=${BOBSHELL_INSTALL_SYSTEMDDIR-$BOBSHELL_INSTALL_ROOT/etc/systemd/system}}"
	: "${BOBSHELL_INSTALL_SYSTEM_PROFILE=${BOBSHELL_INSTALL_PROFILE-$BOBSHELL_INSTALL_ROOT/etc/profile}}"

	# https://wiki.archlinux.org/title/XDG_Base_Directory
	: "${BOBSHELL_INSTALL_USER_BINDIR=${BOBSHELL_INSTALL_BINDIR-$BOBSHELL_INSTALL_ROOT$HOME/.local/bin}}"
	: "${BOBSHELL_INSTALL_USER_CONFDIR=${BOBSHELL_INSTALL_CONFDIR-$BOBSHELL_INSTALL_ROOT$HOME/.config}}"
	: "${BOBSHELL_INSTALL_USER_DATADIR=${BOBSHELL_INSTALL_DATADIR-$BOBSHELL_INSTALL_ROOT$HOME/.local/share}}"
	: "${BOBSHELL_INSTALL_USER_LOCALSTATEDIR=${BOBSHELL_INSTALL_LOCALSTATEDIR-$BOBSHELL_INSTALL_ROOT$HOME/.local/state}}"
	: "${BOBSHELL_INSTALL_USER_CACHEDIR=${BOBSHELL_INSTALL_CACHEDIR-$BOBSHELL_INSTALL_ROOT$HOME/.cache}}"
	: "${BOBSHELL_INSTALL_USER_SYSTEMDDIR=${BOBSHELL_INSTALL_SYSTEMDDIR-$BOBSHELL_INSTALL_ROOT$HOME/.config/systemd/user}}"
	: "${BOBSHELL_INSTALL_USER_PROFILE=${BOBSHELL_INSTALL_PROFILE-$BOBSHELL_INSTALL_ROOT$HOME/.profile}}"

	if [ -z "${BOBSHELL_INSTALL_ROLE:-}" ]; then
		if bobshell_is_root; then
			BOBSHELL_INSTALL_ROLE=SYSTEM
		else
			BOBSHELL_INSTALL_ROLE=USER
		fi
	fi


	if [ SYSTEM = "$BOBSHELL_INSTALL_ROLE" ]; then
		BOBSHELL_INSTALL_BINDIR="$BOBSHELL_INSTALL_SYSTEM_BINDIR"
		BOBSHELL_INSTALL_CONFDIR="$BOBSHELL_INSTALL_SYSTEM_CONFDIR"
		BOBSHELL_INSTALL_DATADIR="$BOBSHELL_INSTALL_SYSTEM_DATADIR"
		BOBSHELL_INSTALL_LOCALSTATEDIR="$BOBSHELL_INSTALL_SYSTEM_LOCALSTATEDIR"
		BOBSHELL_INSTALL_CACHEDIR="$BOBSHELL_INSTALL_SYSTEM_CACHEDIR"
		BOBSHELL_INSTALL_SYSTEMDDIR="$BOBSHELL_INSTALL_SYSTEM_SYSTEMDDIR"
		BOBSHELL_INSTALL_PROFILE="$BOBSHELL_INSTALL_SYSTEM_PROFILE"
	else
		BOBSHELL_INSTALL_BINDIR="$BOBSHELL_INSTALL_USER_BINDIR"
		BOBSHELL_INSTALL_CONFDIR="$BOBSHELL_INSTALL_USER_CONFDIR"
		BOBSHELL_INSTALL_DATADIR="$BOBSHELL_INSTALL_USER_DATADIR"
		BOBSHELL_INSTALL_LOCALSTATEDIR="$BOBSHELL_INSTALL_USER_LOCALSTATEDIR"
		BOBSHELL_INSTALL_CACHEDIR="$BOBSHELL_INSTALL_USER_CACHEDIR"
		BOBSHELL_INSTALL_SYSTEMDDIR="$BOBSHELL_INSTALL_USER_SYSTEMDDIR"
		BOBSHELL_INSTALL_PROFILE="$BOBSHELL_INSTALL_USER_PROFILE"
	fi

		
	: "${BOBSHELL_INSTALL_SYSTEMCTL:=systemctl}"
}






# fun: bobshell_install_service SRCLOCATOR DESTNAME
# use: bobshell_install_service file:target/myservice myservice.service
bobshell_install_service() {
	bobshell_install_service_dir="$BOBSHELL_INSTALL_DESTDIR$BOBSHELL_INSTALL_SYSTEMDDIR"
	mkdir -p "$bobshell_install_service_dir"
	bobshell_copy "$1" "file:$bobshell_install_service_dir/$2"

	
	if [ 0 = "$(id -u)" ]; then
		bobshell_install_service_arg=
	else
		bobshell_install_service_arg='--user'
	fi
	$BOBSHELL_INSTALL_SYSTEMCTL $bobshell_install_service_arg daemon-reload
	$BOBSHELL_INSTALL_SYSTEMCTL $bobshell_install_service_arg enable "$2"
}








# fun: bobshell_install_put SRC DIR DESTNAME MODE
bobshell_install_put() {
	mkdir -p "$BOBSHELL_INSTALL_DESTDIR$2"
	bobshell_copy "$1" "file:$BOBSHELL_INSTALL_DESTDIR$2/$3"
	chmod "$4" "$BOBSHELL_INSTALL_DESTDIR$2/$3"
}

# fun: bobshell_install_binary SRC DESTNAME
# use: bobshell_install_binary target/exesrc.sh mysuperprog
bobshell_install_put_executable() {
	bobshell_install_put "$1" "$BOBSHELL_INSTALL_BINDIR" "$2" u=rwx,go=rx
}

bobshell_install_put_config() {
	bobshell_install_put "$1" "$BOBSHELL_INSTALL_CONFDIR/$BOBSHELL_INSTALL_NAME" "$2" u=rw,go=r
}

bobshell_install_put_data() {
	bobshell_install_put "$1" "$BOBSHELL_INSTALL_DATADIR/$BOBSHELL_INSTALL_NAME" "$2" u=rw,go=r
}

bobshell_install_put_localstate() {
	bobshell_install_put "$1" "$BOBSHELL_INSTALL_LOCALSTATEDIR/$BOBSHELL_INSTALL_NAME" "$2" u=rw,go=r
}

bobshell_install_put_cache() {
	bobshell_install_put "$1" "$BOBSHELL_INSTALL_CACHEDIR/$BOBSHELL_INSTALL_NAME" "$2" u=rw,go=r
}









# fun: bobshell_install_find SYSTEMCANDIDATE USERCANDIDATE
bobshell_install_find() {
	if bobshell_is_not_root && [ -f "$BOBSHELL_INSTALL_DESTDIR$2" ]; then
		printf %s "$2"
		return
	fi

	if [ -f "$BOBSHELL_INSTALL_DESTDIR$1" ]; then
		printf %s "$1"
		return
	fi

	return 1
}

bobshell_install_find_executable() {
	bobshell_install_find "$BOBSHELL_INSTALL_SYSTEM_BINDIR/$1" "$BOBSHELL_INSTALL_USER_BINDIR/$1"
}

bobshell_install_find_config() {
	bobshell_install_find "$BOBSHELL_INSTALL_SYSTEM_CONFDIR/$BOBSHELL_INSTALL_NAME/$1" "$BOBSHELL_INSTALL_USER_CONFDIR/$BOBSHELL_INSTALL_NAME/$1"
}

bobshell_install_find_data() {
	bobshell_install_find "$BOBSHELL_INSTALL_SYSTEM_DATADIR/$BOBSHELL_INSTALL_NAME/$1" "$BOBSHELL_INSTALL_USER_DATADIR/$BOBSHELL_INSTALL_NAME/$1"
}

bobshell_install_find_localstate() {
	bobshell_install_find "$BOBSHELL_INSTALL_SYSTEM_LOCALSTATEDIR/$BOBSHELL_INSTALL_NAME/$1" "$BOBSHELL_INSTALL_USER_LOCALSTATEDIR/$BOBSHELL_INSTALL_NAME/$1"
}

bobshell_install_find_cache() {
	bobshell_install_find "$BOBSHELL_INSTALL_SYSTEM_CACHEDIR/$BOBSHELL_INSTALL_NAME/$1" "$BOBSHELL_INSTALL_USER_CACHEDIR/$BOBSHELL_INSTALL_NAME/$1"
}

















# fun: bobshell_install_get FUN NAME DEST
bobshell_install_get() {
	bobshell_install_get_dest="$3"
	set -- "$1" "$2"
	if bobshell_install_get_found=$("$@"); then
		bobshell_copy "file:$bobshell_install_get_found" "$bobshell_install_get_dest"
		return
	else
		return 1
	fi
}

# fun: bobshell_install_get_executable NAME DEST
bobshell_install_get_executable() {
	bobshell_install_get bobshell_install_find_executable "$1" "$2"
}

# fun: bobshell_install_get_config NAME DEST
bobshell_install_get_config() {
	bobshell_install_get bobshell_install_find_config "$1" "$2"
}

bobshell_install_get_data() {
	bobshell_install_get bobshell_install_find_data "$1" "$2"
}

bobshell_install_get_localstate() {
	bobshell_install_get bobshell_install_find_localstate "$1" "$2"
}

bobshell_install_get_cache() {
	bobshell_install_get bobshell_install_find_cache "$1" "$2"
}



# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/scope.sh






bobshell_scope_names() {
	for bobshell_scope_names_scope in "$@"; do
		bobshell_scope_names_all=$(set | sed -n "s/^\($bobshell_scope_names_scope[A-Za-z_0-9]*\)=.*$/\1/pg" | sort -u)
		for bobshell_scope_names_item in $bobshell_scope_names_all; do
			if bobshell_isset "$bobshell_scope_names_item"; then
				printf ' %s' "$bobshell_scope_names_item"
			fi
		done
	done
	unset bobshell_scope_names_all bobshell_scope_names_scope bobshell_scope_names_item
}



bobshell_scope_unset() {
	for bobshell_scope_unset_name in $(bobshell_scope_names "$@"); do
		unset "$bobshell_scope_unset_name"
	done
	unset bobshell_scope_unset_name
}



bobshell_scope_export() {
	for bobshell_scope_export_name in $(bobshell_scope_names "$@"); do
		export "$bobshell_scope_export_name"
	done
	unset bobshell_scope_export_name
}



bobshell_scope_env() {
	bobshell_scope_env_result=
	for bobshell_scope_env_name in $(bobshell_scope_names "$1"); do
		bobshell_scope_env_result="$bobshell_scope_env_result$bobshell_scope_env_name="
		bobshell_scope_env_value=$(bobshell_getvar "$bobshell_scope_env_name")
		bobshell_scope_env_value=$(bobshell_quote "$bobshell_scope_env_value")
		bobshell_scope_env_result="$bobshell_scope_env_result$bobshell_scope_env_value$bobshell_newline"
	done
	bobshell_copy var:bobshell_scope_env_result "$2"
	unset bobshell_scope_env_result bobshell_scope_env_name bobshell_scope_env_value
}


# fun: bobshell_scope_copy SRCSCOPE DESTSCOPE
bobshell_scope_copy() {
	for bobshell_scope_copy_name in $(bobshell_scope_names "$1"); do
		bobshell_scope_copy_value=$(bobshell_getvar "$bobshell_scope_copy_name")
		bobshell_remove_prefix "$bobshell_scope_copy_name" "$1" bobshell_scope_copy_name
		bobshell_putvar "$2$bobshell_scope_copy_name" "$bobshell_scope_copy_value"
	done
	unset bobshell_scope_copy_name bobshell_scope_copy_value
}


# fun: bobshell_scope_mirror SRCSCOPE DESTSCOPE
bobshell_scope_mirror() {
	bobshell_scope_unset "$2"
	bobshell_scope_copy "$@"
}





install_shelduck "$@"



