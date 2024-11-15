#!/bin/sh
set -eu
# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit install.sh.in and run sh ./run build to regenerate it

# shelduck: source for file://install.sh.in


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




	# install executable
	mkdir -p "$DESTDIR$BINDIR"
	cat > "$DESTDIR$BINDIR/shelduck" <<eof
#!/bin/sh
main() {
	shelduck "\$@"
}
. "$DATAROOTDIR/shelduck/shelduck.sh"
main "\$@"
eof
	chmod +x "$DESTDIR$BINDIR/shelduck"



	# uninsatller
	mkdir -p "$DESTDIR$DATAROOTDIR/shelduck"
	cat > "$DESTDIR$DATAROOTDIR/shelduck/uninstall" << eof
#!/bin/sh
rm -f "$DATAROOTDIR/shelduck" "$BINDIR/shelduck_resolve" "$CACHEDIR/shelduck"
eof
	chmod +x "$DESTDIR$DATAROOTDIR/shelduck/uninstall"

	#
	if command_available shelduck_resolve; then
		log 'shelduck_resolve was successfully installed to %s, which seems to be already in the PATH' "$BINDIR"
		return
	fi

	log "adding $BINDIR to path"

	printf '\nPATH="%s:$PATH"' "$BINDIR" >> "$DESTDIR$PROFILE_FILE"

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
	# printf format should be in "$@"
	# shellcheck disable=SC2059
	bobshell_log_message=$(printf "$@")
	printf '%s: %s\n' "$0" "$bobshell_log_message" >&2
	unset bobshell_log_message
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


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# STRING MANUPULATION





# use: bobshell_starts_with hello he && echo "$rest" # prints llo
bobshell_starts_with() {
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
		(*"$2"*) return 0 ;;
	esac
	return 1
}

# fun: bobshell_contains STR SUBSTR [PREFIX [SUFFIX]]
bobshell_split_once() {
	set -- "$1" "$2" "$3" "$4" "${1#*"$2"}"
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

# txt: заменить в $1 все вхождения строки $2 на строку $3 и записать результат в переменную $4
# use: replace_substring hello e E
bobshell_replace() {
  	# https://freebsdfrau.gitbook.io/serious-shell-programming/string-functions/replace_substringall
	bobshell_replace_str="$1"
	while bobshell_contains "$bobshell_replace_str" "$2" bobshell_replace_left bobshell_replace_str; do
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
		if ! bobshell_split_once \
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



bobshell_fetch_url() {
	if bobshell_remove_prefix "$1" 'file://' bobshell_fetch_url_file_path; then
		# shellcheck disable=SC2154
		# bobshell_remove_prefix sets variable bobshell_fetch_url_file_path indirectly
		cat "$bobshell_fetch_url_file_path"
		unset bobshell_fetch_url_file_path
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

