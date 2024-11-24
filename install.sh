#!/bin/sh
set -eu
# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit install.sh.in and run sh ./run build to regenerate it

# shelduck: source for file:///home/user/box/workspace/shelduck/install.sh.in


# shelduck_src
# env: PREFIX?
#      DESTDIR
install_shelduck() {

	: "${DESTDIR:=}"

	if [ 0 = "$(id -u)" ]; then
		: "${PREFIX:=/opt}"
		: "${SYSCONFIGDIR:=/etc/opt}"
		: "${PROFILE_FILE:=$SYSCONFIGDIR/profile}"
		: "${CACHEDIR:=/var/opt/cache}"
	else
		: "${PREFIX:=$HOME/.local}"
		: "${SYSCONFIGDIR:=$HOME/.config}"
		: "${PROFILE_FILE:=$HOME/.profile}"
		: "${CACHEDIR:=$HOME/.cache}"
	fi
	: "${BINDIR:=$PREFIX/bin}"
	: "${DATAROOTDIR:=$PREFIX/share}"


	mkdir -p "$DESTDIR$BINDIR" "$DESTDIR$CACHEDIR/shelduck" "$DESTDIR$DATAROOTDIR/shelduck"

	# install
	mkdir -p "$DESTDIR$DATAROOTDIR/shelduck"
	: "${SHELDUCK_LIBRARY_URL:=https://raw.githubusercontent.com/legeyda/shelduck/refs/heads/main/shelduck.sh}"
	fetch_url "$SHELDUCK_LIBRARY_URL" > "$DESTDIR$DATAROOTDIR/shelduck/shelduck.sh"


	install_executable shelduck <<eof
#!/bin/sh
set -eu
if [ import = "\${1:-}" ]; then
	shift
	printf 'import subcommand not available when run from installed script %s\n' "\$0"
	printf "Instead source library:\n"
	printf '. "%s"\n' '$DESTDIR$DATAROOTDIR/shelduck/shelduck.sh'
	printf 'shelduck import'
	printf ' %s' "\$@"
	exit 1
fi
. '$DATAROOTDIR/shelduck/shelduck.sh'
shelduck "\$@"
eof

	install_executable shelduck_run <<eof
#!/bin/sh
set -eu
. '$DATAROOTDIR/shelduck/shelduck.sh'
shelduck_run "\$@"
eof



	# uninsatller
	mkdir -p "$DESTDIR$DATAROOTDIR/shelduck"
	cat > "$DESTDIR$DATAROOTDIR/shelduck/uninstall" << eof
#!/bin/sh
rm -f "$DATAROOTDIR/shelduck" "$BINDIR/shelduck" "$CACHEDIR/shelduck"
eof
	chmod +x "$DESTDIR$DATAROOTDIR/shelduck/uninstall"

	#
	if command_available shelduck; then
		log 'shelduck_resolve was successfully installed to %s, which seems to be already in the PATH' "$BINDIR"
		return
	fi

	log "adding $BINDIR to path"

	printf '\nPATH="%s:$PATH"' "$BINDIR" >> "$DESTDIR$PROFILE_FILE"

}

install_executable() {
	mkdir -p "$DESTDIR$BINDIR"
	cat > "$DESTDIR$BINDIR/$1"
	chmod +x "$DESTDIR$BINDIR/$1"
}



# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh

# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# STRING MANUPULATION





# use: bobshell_starts_with hello he && echo "$rest" # prints llo
bobshell_starts_with() {
	bobshell_require_empty "bobshell_starts_with takes 2 arguments, 3 given, did you mean bobshell_remove_prefix?"
	case "$1" in
		("$2"*) return 0
	esac
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
	bobshell_putvar "$3" "$4"	
}

# use: bobshell_starts_with hello he rest && echo "$rest" # prints llo
bobshell_ends_with() {
	bobshell_require_empty "bobshell_ends_with takes 2 arguments, 3 given, did you mean bobshell_remove_suffix?"
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
	bobshell_putvar "$3" "$4"
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


bobshell_die() {
  # https://github.com/biox/pa/blob/main/pa
  printf '%s: %s.\n' "$(basename "$0")" "${*:-error}" >&2
  exit 1
}


# use isset unreliablevar
bobshell_isset() {
	eval "test \"\${$1+defined}\" = defined"
}

#  
bobshell_isset_1() {
	eval "test \"\${1+defined}\" = defined"
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
	# printf format should be in "$@"
	# shellcheck disable=SC2059
	bobshell_log_message=$(printf "$@")
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


#fun: bobshell_resolve_url URL [BASEURL]
bobshell_resolve_url() {
	# todo by default BASEURL is $(realpath "$(pwd)")
	if   bobshell_remove_prefix "$1" file:// bobshell_resolve_url_path; then
		bobshell_resolve_url_path=$(realpath "$bobshell_resolve_url_path")
		printf 'file://%s' "$bobshell_resolve_url_path"
	elif bobshell_starts_with "$1" http:// \
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
		while bobshell_remove_prefix "$bobshell_resolve_url_value" './' bobshell_resolve_url_value; do
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




 # shelduck: alias for bobshell_fetch_url (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/url.sh)
fetch_url() {
	bobshell_fetch_url "$@"
}


install_shelduck "$@"

