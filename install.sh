#!/bin/sh
set -eu
# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit install.sh.in and run sh ./run build to regenerate it

# shelduck: source for file://install.sh.in


# shelduck_src
# env: PREFIX?
#      DESTDIR
install_shelduck() {
	if command_available shelduck; then
		errcho "shelduck seems to be already installed as $(command -v shelduck)"
		return
	fi

	: "${DESTDIR:=}"
	: "${PREFIX:=/opt}"
	: "${BINDIR:=$PREFIX/bin}"
	: "${DATAROOTDIR:=$PREFIX/share}"

	if [ 0 = "$(id -u)" ]; then
		: "${SYSCONFIGDIR:=/etc/opt}"
		: "${PROFILE_FILE:=$SYSCONFIGDIR/profile}"
		: "${CACHEDIR:=/var/opt/cache}"
	else
		: "${SYSCONFIGDIR:=$HOME/.config}"
		: "${PROFILE_FILE:=$HOME/.profile}"
		: "${CACHEDIR:=$HOME/.cache}"
	fi

	# if [ -f "" ]; then
	# 	die "something wrong: $install_shelduck_bin_dir/shelduck already exists"
	# fi


	mkdir -p "$DESTDIR$BINDIR" "$DESTDIR$CACHEDIR/shelduck" "$DESTDIR$DATAROOTDIR/shelduck"

	# install
	mkdir -p "$DESTDIR$DATAROOTDIR/shelduck"
	: "${SHELDUCK_LIBRARY_URL:=https://raw.githubusercontent.com/legeyda/shelduck/refs/heads/main/shelduck.sh}"
	fetch_url "$SHELDUCK_LIBRARY_URL" > "$DESTDIR$DATAROOTDIR/shelduck/shelduck.sh"


	# build installer
	install_executable shelduck_resolve

	# uninsatller
	install_uninstaller

	#
	if command_avalable shelduck; then
		log 'shelduck_resolve was successfully installed to %s, which seems to be already in the PATH' "$BINDIR"
		return
	fi










	#
	install_shelduck_marker='end of'
	install_shelduck_marker="$install_shelduck_marker installer"

	# 
	install_shelduck_script="$(cat "$0")"
	printf %s "${install_shelduck_script#*"$install_shelduck_marker"}" > "$install_shelduck_bin_dir/shelduck"
	chmod ugo+x "$install_shelduck_bin_dir/shelduck"



	# 
	mkdir -p "$(dirname "$install_shelduck_profile_script")"



	# shellcheck disable=SC2016
	line_in_file='PATH=%s:$PATH'
	grep --quiet -- "$line_in_file" 
	printf '\n\n#shelduck installer\n%s' "$line_in_file" >> "$install_shelduck_profile_script"

	#
	if ! command -v shelduck; then
		die "something wrong: shelduck was installed as $install_shelduck_bin_dir/shelduck, dir added to path in $install_shelduck_profile_script, but not accessible"
	fi

	printf 'shelduck was successfully installed to %s' "$install_shelduck_bin_dir" >&2
}

install_executable() {
	mkdir -p "$DESTDIR$BINDIR"
	cat > "$DESTDIR$BINDIR/$1" <<eof
#!/bin/sh
main() {
	$1 "\$@"
}
. "$DATAROOTDIR/shelduck/shelduck.sh"
main "\$@"
eof
	chmod +x "$DESTDIR$BINDIR/$1"
}

install_uninstaller() {
	mkdir -p "$DESTDIR$DATAROOTDIR/shelduck"
	cat > "$DESTDIR$DATAROOTDIR/shelduck/uninstall" << eof
#!/bin/sh
rm -f "$DESTDIR$DATAROOTDIR/shelduck" "$DESTDIR$BINDIR/shelduck_resolve" "$DESTDIR$CACHEDIR/shelduck"
eof
	chmod +x "$DESTDIR$DATAROOTDIR/shelduck/uninstall"
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
  printf '%s: %s\n' "$0" "$*" >&2
}


 # shelduck: alias for bobshell_die (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh)
die() {
	bobshell_die "$@"
}



 # shelduck: alias for bobshell_log (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh)
log() {
	bobshell_log "$@"
}

# shellcheck disable=SC2148


# shelduck: source for https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# STRING MANUPULATION



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


bobshell_contains() {
	case "$1" in
		*"$2"* ) return 0 ;;
		*) return 1 ;;
	esac
}

bobshell_assing_new_line() {
	bobshell_putvar "$1" '
'
}

bobshell_newline='
'



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




 # shelduck: alias for bobshell_fetch_url (from https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/url.sh)
fetch_url() {
	bobshell_fetch_url "$@"
}


