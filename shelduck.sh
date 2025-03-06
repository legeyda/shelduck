# THIS FILE IS GENERATED AUTOMATICALLY, DO NOT EDIT IT MANUALLY.
# Instead, edit shelduck.sh.in and run sh ./run build to regenerate it


# see https://github.com/ajdiaz/bashdoc


# fun: shelduck CLIARGS...
# api: public
# env: SHELDUCK_BASE_URL
#      SHELDUCK_LIBRARY_PATH
#      SHELDUCK_URL_RULES
shelduck() {
	bobshell_require_not_empty "${1:-}" 'shelduck: subcommad expected, see shelduck usage'
	case "$1" in
		(usage|import|resolve|run)
				shelduck_subcommand="$1"
				shift
				"shelduck_$shelduck_subcommand" "$@" ;;
		(*) printf 'unknown subcommand %s, see shelduck usage' "$1"
	esac
}

# api: private
shelduck_ensure_base_url() {
	# guess base url
	if [ -z "${shelduck_base_url:-}" ]; then
		if [ -n "${SHELDUCK_BASE_URL:-}" ]; then
			shelduck_base_url="$SHELDUCK_BASE_URL"
		else
			shelduck_base_url=$(pwd)
			shelduck_base_url="file://$shelduck_base_url"
		fi
	fi
}



# fun: shelduck_run URL [ARGS...]
# api: private
shelduck_run() {
	# parse cli
	bobshell_isset_1 "$@" || bobshell_die '"shelduck run" requires at least 1 argument'
	shelduck_run_url=$(shelduck_fix_url "$1")
	shift
	shelduck_run_args="$(bobshell_quote "$@")"


	# save vars before recursive_call
	set -- "$shelduck_run_args" # save latest run args, since recursive imports use it # todo needed?
	
	# delegate to shelduck_exec
	shelduck_exec '' "$shelduck_run_url" "$shelduck_run_args"
	unset shelduck_run_url shelduck_run_args

	# restore state after recursive call
	shelduck_run_args="$1"

}


shelduck_fix_url() {
	if [ -z "$1" ]; then
		bobshell_die "shelduck: invalid url"
	fi

	shelduck_ensure_base_url
	if bobshell_locator_is_remote "$1" || bobshell_locator_is_file "$1" || ! bobshell_locator_parse "$1"; then
		shelduck_fix_url=$(bobshell_resolve_url "$1" "$shelduck_base_url")
		if [ -n "${SHELDUCK_URL_RULES:-}" ]; then
			shelduck_fix_url=$(shelduck_apply_rules "$shelduck_fix_url" "$SHELDUCK_URL_RULES")
		fi
		printf %s "$shelduck_fix_url"
		unset shelduck_fix_url
	else
		printf %s "$1"
	fi
}



shelduck_parse_import_cli() {
	bobshell_require_not_empty "${1:-}" '"shelduck import" requires at least 1 argument.'
	shelduck_import_aliases=
	shelduck_import_url=
	while bobshell_isset_1 "$@"; do
		case "$1" in
			(-a|--alias)
				if ! bobshell_isset_2 "$@"; then
					bobshell_die "option '$1' (alias) requires argument"
				fi
				shift
				shelduck_import_cli_alias "$1"
				shift
				;;

			(--alias=*)
				bobshell_remove_prefix "$1" --alias= shelduck_analyze_cli_alias
				shift
				shelduck_import_cli_alias "$shelduck_analyze_cli_alias"
				;;

			(*)
				break
				;;
		esac
	done

	if [ -z "${1:-}" ]; then
		bobshell_die "url expected to be nonempty"
	fi
	shelduck_import_url="$1"
	
	if bobshell_isset_2 "$@"; then
		bobshell_die "unexpected argument \"$2\""
	fi
	
}


shelduck_import_cli_alias() {
	if [ -z "$1" ]; then
		bobshell_die 'alias cannot be empty'
	fi
	shelduck_import_aliases="$shelduck_import_aliases $1"
}

shelduck_import_usage() {
	printf %s 'Import library.
	
Usage: shelduck import [OPTIONS] URL

Options:

   -a, --alias ALIAS    Defina alias for functions      
'
}





# fun: shelduck_apply_rules VALUE RULES
shelduck_apply_rules() {
	shelduck_apply_rules_result="$1"
	shelduck_apply_rules_rules="${2:-}"

	while [ -n "$shelduck_apply_rules_rules" ]; do
		if ! bobshell_split_first "$shelduck_apply_rules_rules" ',' shelduck_apply_rules_rule shelduck_apply_rules_rules; then
			shelduck_apply_rules_rule="$shelduck_apply_rules_rules"
			shelduck_apply_rules_rules=
		fi
		
		shelduck_apply_rules_key=
		shelduck_apply_rules_value=
		bobshell_split_first "$shelduck_apply_rules_rule" = shelduck_apply_rules_key shelduck_apply_rules_value
		shelduck_apply_rules_result=$(bobshell_replace "$shelduck_apply_rules_result" "$shelduck_apply_rules_key" "$shelduck_apply_rules_value")
	done
	printf %s "$shelduck_apply_rules_result"

	unset shelduck_apply_rules_result
	unset shelduck_apply_rules_rules shelduck_apply_rules_rule
	unset shelduck_apply_rules_key shelduck_apply_rules_value
}




# fun: shelduck_eval_with_args SCRIPT [ARGS...]
shelduck_eval_with_args() {
	shelduck_eval_with_args_script="$1"
	shift
	eval "$shelduck_eval_with_args_script" # todo check if it is message add arguments
}


# shelduck_run and shelduck_import are very similar, but:
# - import requires url, since it checks for duplicates, whereas run does not requies url
# - import checks for duplicate urls, run not
# - import takes args from run_args
# - run takes args from command, and restores


# fun: shelduck_resolve CLIARGS...
# api: private
# env: shelduck_base_url
shelduck_import() {
	shelduck_parse_import_cli "$@"
	shelduck_import_url=$(shelduck_fix_url "$shelduck_import_url")

	# check for duplicates
	: "${shelduck_import_history:=}"
	if bobshell_contains "$shelduck_import_history" "$shelduck_import_url"; then
		# todo maybe base url is needed
		shelduck_import_origin=$(shelduck_print_origin "$shelduck_import_url")
		shelduck_import_addition=$(shelduck_print_addition "$shelduck_import_origin" "$shelduck_import_url" "$shelduck_import_aliases")
		eval "$shelduck_import_addition"
		unset shelduck_import_origin shelduck_import_addition
		return
	fi
	shelduck_import_history="$shelduck_import_history $shelduck_import_url"
	
	# delegate to shelduck_exec
	shelduck_exec "$shelduck_import_aliases" "$shelduck_import_url" ''
	unset shelduck_import_aliases shelduck_import_url shelduck_analyze_cli_args

}




# fun: shelduck_exec ALIASES ABSURL ARGS
shelduck_exec() {
	shelduck_ensure_base_url


	# exec absurl ABSURL
	if [ -n "$2" ]; then
		shelduck_alias_strategy=wrap
		shelduck_exec_origin=$(shelduck_print_origin "$2")
		shelduck_event_url "$2" "$shelduck_exec_origin"
		shelduck_exec_additions=$(shelduck_print_addition "$shelduck_exec_origin" "$2" "$1")

		# save state before recursive call
		set -- "$shelduck_base_url" "$1" "$2" "$3" shelduck_eval_with_args "$shelduck_exec_origin$shelduck_exec_additions"
		if [ -n "$4" ]; then
			eval "set -- \"\$@\" $4"
		fi
		
		# recursive call
		shelduck_update_base_url "$3"
		shelduck_shift_exec 4 "$@"

		# restore state after recursive call
		shelduck_base_url="$1"
		shift
	fi
	
}

# fun: shelduck_event_url URL TEXT
# txt: event listener to extend shelduck core
shelduck_event_url() {
	true
}

# fun: shelduck_shift_exec SHIFTNUM IGNORED ... COMMAND [ARGS...]
shelduck_shift_exec() {
	shift "$1"
	shift
	"$@"
}

# fun: shelduck_update_base_url URL
shelduck_update_base_url() {
	if bobshell_locator_is_file "$1" || bobshell_locator_is_remote "$1"; then
		shelduck_base_url=$(bobshell_base_url "$1")
	fi
}



# api: private
shelduck_usage() {
	printf 'Usage: shelduck SUBCOMMAND [ARGS...]\n'
	printf 'Commands:\n'
	printf '    usage\n'
	printf '    import\n'
	printf '    resolve\n'
	printf '    run\n'
}


# fun: shelduck_resolve CLIARGS...
# api: private
shelduck_resolve() {
	shelduck_ensure_base_url

	# set starting parameters
	shelduck_print_history=
	shelduck_alias_strategy="${SHELDUCK_ALIAS_STRATEGY:-wrap}"
	
	# delegate
	shelduck_print "$@"
}



# fun: shelduck_print CLIARGS...
# env: shelduck_print_history
#      shelduck_alias_strategy
# txt: parse cli and delegate to shelduck_print_tree
# api: private
shelduck_print() {

	shelduck_print_initial_base_url="$shelduck_base_url" # todo is shelduck_print_initial_base_url needed?

	# parse cli
	shelduck_parse_import_cli "$@"
	shelduck_print_url=$(shelduck_fix_url "$shelduck_import_url")
	unset shelduck_import_url
	shelduck_print_aliases="$shelduck_import_aliases"
	unset shelduck_import_aliases


	# load script
	shelduck_print_script=$(shelduck_print_origin "$shelduck_print_url")
	shelduck_event_url "$shelduck_print_url" "$shelduck_print_script"
	
	# save variables to local array before subsequent (possibly recursive) calls
	set -- "$shelduck_print_script" "$shelduck_print_url" "$shelduck_print_aliases" "$shelduck_base_url" "$shelduck_print_initial_base_url"

	# check if dependency was already compiled
	if ! bobshell_contains "$shelduck_print_history" "$2"; then
		shelduck_print_history="$shelduck_print_history $2"

		shelduck_update_base_url "$shelduck_print_url"

		# recursive call
		#shelduck_print_compile_args=$(bobshell_quote "$@")
		shelduck_compile "$@"

		# restore variables from local array after recursive call
		shelduck_base_url="$4"
		shelduck_print_initial_base_url="$5"

	fi

	# print additions, if needed
	shelduck_print_addition "$@"

	shelduck_base_url="$shelduck_print_initial_base_url"
}




# fun: shelduck_compile SCRIPT URL
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
		if bobshell_remove_prefix "$shelduck_compile_input" 'shelduck import ' shelduck_compile_after; then
			shelduck_compile_input="$shelduck_compile_after"
		elif ! bobshell_split_first "$shelduck_compile_input" "${bobshell_newline}shelduck import " shelduck_compile_before shelduck_compile_after; then
			break
		else
			# print everything before the first found shelduck command
			shelduck_rewrite "$shelduck_compile_before$bobshell_newline" "$@"
			shelduck_compile_input="$shelduck_compile_after$bobshell_newline"
		fi

		

		shelduck_compile_command=
		while true; do
			if ! bobshell_split_first "$shelduck_compile_input" "${bobshell_newline}" shelduck_compile_before shelduck_compile_after; then
				shelduck_compile_command="$shelduck_compile_input"
				shelduck_compile_input=
				break
			fi

			if ! bobshell_remove_suffix "$shelduck_compile_before" '\' shelduck_compile_before; then
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

		# before recursive call, save variables to local array
		set -- "$shelduck_compile_input" "$@"

		# recursive call, concously not double qouting
		# shellcheck disable=SC2086
		shelduck_print $shelduck_compile_command

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




# fun: shelduck_rewrite ORIGCONTENT URL
# txt: rewrite original script (e.g. rename functions)
# api: private
shelduck_rewrite() {
	if [ rename = "${shelduck_alias_strategy:-}" ]; then
		bobshell_die "shelduck_alias_strategy: value $shelduck_alias_strategy not supported"
	fi
	shelduck_rewrite_data="$1"
	if bobshell_remove_prefix "$shelduck_rewrite_data" "#!/usr/bin/env shelduck_run$bobshell_newline" shelduck_rewrite_suffix; then
		shelduck_rewrite_data="#!/bin/sh$bobshell_newline$shelduck_rewrite_suffix"
	fi
	printf %s "$shelduck_rewrite_data"
	unset shelduck_rewrite_data shelduck_rewrite_suffix
}




# fun: shelduck_print_addition ORIGCONTENT ABSURL ALIASES
# txt: print script additional code (e.g. aliases)
# api: private
shelduck_print_addition() {

	if [ wrap != "${shelduck_alias_strategy:-}" ]; then
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
		if ! bobshell_split_first "$arg" = key value; then
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
shelduck_cached_fetch_url() (
	# bypass cache if local file
	if bobshell_remove_prefix "$1" 'file://' shelduck_cached_fetch_url_path; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		if ! [ -f "$shelduck_cached_fetch_url_path" ]; then
			bobshell_die "shelduck: fetch error '$1': file '$shelduck_cached_fetch_url_path' not found"
		fi
		cat "$shelduck_cached_fetch_url_path" || bobshell_die "shelduck: fetch error '$1': error loading '$shelduck_cached_fetch_url_path'"
		unset shelduck_cached_fetch_url_path
		return
	elif bobshell_locator_is_remote "$1" || ! bobshell_locator_parse "$1"; then

		# init bobshell_install_* library
		: "${SHELDUCK_INSTALL_NAME:=shelduck}"
		bobshell_scope_mirror SHELDUCK_INSTALL_ BOBSHELL_INSTALL_
		bobshell_install_init

		# key
		shelduck_cached_fetch_url_key=$(printf %s "$1" | sed 's/[\/<>:\\|?*]/-/g')


		shelduck_cached_fetch_url_path=
		if shelduck_cached_fetch_url_path=$(bobshell_install_find_cache "$shelduck_cached_fetch_url_key"); then
			# todo expiration
			cat "$shelduck_cached_fetch_url_path"
			unset shelduck_cached_fetch_url_path
			return
		fi
		
		shelduck_cached_fetch_url_result=$(bobshell_fetch_url "$1" || bobshell_die "shelduck: fetch error '$1': error downloading '$1'")

		bobshell_install_put_cache var:shelduck_cached_fetch_url_result "$shelduck_cached_fetch_url_key"
		printf %s "$shelduck_cached_fetch_url_result"
	else
		bobshell_resource_copy "$1" stdout:
	fi

)

# disable recursive dependency resolution when building shelduck itself
# shelduck import string.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import require.sh

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



# STRING MANUPULATION

# disable recursive dependency resolution when building shelduck itself
# shelduck import base.sh



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


# shellcheck disable=SC2148

# disable recursive dependency resolution when building shelduck itself
# shelduck import ./base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ./string.sh


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




# disable recursive dependency resolution when building shelduck itself
# shelduck import base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import resource/copy.sh


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
	bobshell_resource_copy var:bobshell_scope_env_result "$2"
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



# disable recursive dependency resolution when building shelduck itself
# shelduck import string.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import util.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import resource/copy.sh


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
	bobshell_resource_copy "$1" "file:$bobshell_install_service_dir/$2"

	
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
	bobshell_resource_copy "$1" "file:$BOBSHELL_INSTALL_DESTDIR$2/$3"
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
		bobshell_resource_copy "file:$bobshell_install_get_found" "$bobshell_install_get_dest"
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



# disable recursive dependency resolution when building shelduck itself
# shelduck import ../string.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ../resource/copy.sh


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
		bobshell_resource_copy_val_to_var "$bobshell_locator_parse_type" "$2"
	fi
	if [ -n "${3:-}" ]; then
		bobshell_resource_copy_val_to_var "$bobshell_locator_parse_ref" "$3"
	fi
}



# disable recursive dependency resolution when building shelduck itself
# shelduck import ../base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ../string.sh

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




# disable recursive dependency resolution when building shelduck itself
# shelduck import ../string.sh

bobshell_locator_is_remote() {
	bobshell_remove_prefix "$1" http:// "${2:-}" \
	  || bobshell_remove_prefix "$1" https:// "${2:-}" \
	  || bobshell_remove_prefix "$1" ftp:// "${2:-}"\
	  || bobshell_remove_prefix "$1" ftps:// "${2:-}"
}




# disable recursive dependency resolution when building shelduck itself
# shelduck import ../locator/parse.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ../resource/copy.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ../base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import ../string.sh



# fun: bobshell_resource_copy SOURCE DESTINATION
bobshell_resource_copy() {
	bobshell_locator_parse "$1" bobshell_resource_copy_source_type      bobshell_resource_copy_source_ref
	bobshell_locator_parse "$2" bobshell_resource_copy_destination_type bobshell_resource_copy_destination_ref


	bobshell_resource_copy_command="bobshell_resource_copy_${bobshell_resource_copy_source_type}_to_${bobshell_resource_copy_destination_type}"
	if ! bobshell_command_available "$bobshell_resource_copy_command"; then
		bobshell_die "bobshell_resource_copy: unsupported copy $bobshell_resource_copy_source_type to $bobshell_resource_copy_destination_type"
	fi

	"$bobshell_resource_copy_command" "$bobshell_resource_copy_source_ref" "$bobshell_resource_copy_destination_ref"
	
	unset bobshell_resource_copy_source_type bobshell_resource_copy_source_ref
	unset bobshell_resource_copy_destination_type bobshell_resource_copy_destination_ref
}


bobshell_resource_copy_to_val()           { bobshell_die 'cannot write to val resource'; }
bobshell_resource_copy_eval()             { bobshell_die 'eval resource cannot be destination'; }
bobshell_resource_copy_to_stdin()         { bobshell_die 'cannot write to stdin resource'; }
bobshell_resource_copy_stdout()           { bobshell_die 'cannot read from stdout resource'; }
bobshell_resource_copy_to_url()           { bobshell_die 'cannot write to stdin resource'; }



bobshell_resource_copy_val_to_val()       { test "$1" != "$2" && bobshell_resource_copy_to_val; }
bobshell_resource_copy_val_to_var()       { eval "$2='$1'"; }
bobshell_resource_copy_val_to_eval()      { eval "$1"; }
bobshell_resource_copy_val_to_stdin()     { bobshell_resource_copy_to_stdin; }
bobshell_resource_copy_val_to_stdout()    { printf %s "$1"; }
bobshell_resource_copy_val_to_file()      { printf %s "$1" > "$2"; }
bobshell_resource_copy_val_to_url()       { bobshell_resource_copy_to_url; }



bobshell_resource_copy_var_to_val()       { bobshell_resource_copy_to_val; }
bobshell_resource_copy_var_to_var()       { test "$1" != "$2" && eval "$2=\"\$$1\""; }
bobshell_resource_copy_var_to_eval()      { eval "bobshell_resource_copy_var_to_eval \"\$$1\""; }
bobshell_resource_copy_var_to_stdin()     { bobshell_resource_copy_to_stdin; }
bobshell_resource_copy_var_to_stdout()    { eval "printf %s \"\$$1\""; }
bobshell_resource_copy_var_to_file()      { eval "printf %s \"\$$1\"" > "$2"; }
bobshell_resource_copy_var_to_url()       { bobshell_resource_copy_to_url; }



bobshell_resource_copy_eval_to_val()      { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_var()      { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_eval()     { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_stdin()    { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_stdout()   { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_file()     { bobshell_resource_copy_eval; }
bobshell_resource_copy_eval_to_url()      { bobshell_resource_copy_eval; }



bobshell_resource_copy_stdin_to_val()     { bobshell_resource_copy_to_val; }
bobshell_resource_copy_stdin_to_var()     { eval "$2=\$(cat)"; }
bobshell_resource_copy_stdin_to_eval()    {
	bobshell_resource_copy_stdin_to_var "$1" bobshell_resource_copy_stdin_to_eval_data
	bobshell_resource_copy_var_to_eval bobshell_resource_copy_stdin_to_eval_data ''
	unset bobshell_resource_copy_stdin_to_eval_data; 
}
bobshell_resource_copy_stdin_to_stdin()   { bobshell_resource_copy_to_stdin; }
bobshell_resource_copy_stdin_to_stdout()  { cat; }
bobshell_resource_copy_stdin_to_file()    { cat > "$2"; }
bobshell_resource_copy_stdin_to_url()     { bobshell_resource_copy_to_url; }



bobshell_resource_copy_stdout_to_val()    { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_var()    { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_eval()   { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_stdin()  { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_stdout() { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_file()   { bobshell_resource_copy_stdout; }
bobshell_resource_copy_stdout_to_url()    { bobshell_resource_copy_to_url; }



bobshell_resource_copy_file_to_val()      { bobshell_resource_copy_to_val; }
bobshell_resource_copy_file_to_var()      { eval "$2=\$(cat '$1')"; }
bobshell_resource_copy_file_to_eval()     {
	bobshell_resource_copy_file_to_var "$1" bobshell_resource_copy_file_to_eval_data
	bobshell_resource_copy_var_to_eval bobshell_resource_copy_file_to_eval_data ''
	unset bobshell_resource_copy_file_to_eval_data; 
}
bobshell_resource_copy_file_to_stdin()    { bobshell_resource_copy_to_stdin; }
bobshell_resource_copy_file_to_stdout()   { cat "$1"; }
bobshell_resource_copy_file_to_file()     { test "$1" != "$2" && { mkdir -p "$(dirname "$2")" && rm -rf "$2" && cp -f "$1" "$2";}; }
bobshell_resource_copy_file_to_url()      { bobshell_resource_copy_to_url; }



bobshell_resource_copy_url_to_val()       { bobshell_resource_copy_to_val; }
bobshell_resource_copy_url_to_var()       { bobshell_fetch_url "$1" | bobshell_resource_copy_stdin_to_var '' "$2"; }
bobshell_resource_copy_url_to_eval()      { bobshell_fetch_url "$1" | bobshell_resource_copy_stdin_to_var '' "$2"; }
bobshell_resource_copy_url_to_stdin()     { bobshell_resource_copy_to_stdin; }
bobshell_resource_copy_url_to_stdout()    { bobshell_fetch_url "$1"; }
bobshell_resource_copy_url_to_file()      { bobshell_fetch_url "$1" | bobshell_resource_copy_stdin_to_file '' "$2"; }
bobshell_resource_copy_url_to_url()       { bobshell_resource_copy_to_url; }




# disable recursive dependency resolution when building shelduck itself
# shelduck import base.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import string.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import git.sh
# disable recursive dependency resolution when building shelduck itself
# shelduck import resource/copy.sh


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
	bobshell_resource_copy "$1" var:bobshell_eval_script
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


