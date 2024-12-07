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
		shelduck_base_url=$(pwd)
		shelduck_base_url="file://$shelduck_base_url"
	fi
}



# fun: shelduck_run URL CLIARGS...
# api: private
shelduck_run() {
	shelduck_ensure_base_url

	# todo save (and restore) old run_args
	# todo apply url rules

	# parse arguments
	shelduck_analyze_cli "$@"

	# save vars before recursive_call
	set -- "${shelduck_run_args:-}"
	
	# delegate to shelduck_exec
	shelduck_run_args="$shelduck_analyze_cli_args" # save latest run args, since recursive imports use it
	shelduck_exec "$shelduck_analyze_cli_aliases" "$shelduck_analyze_cli_command" "$shelduck_analyze_cli_url" "$shelduck_analyze_cli_args"
	unset shelduck_analyze_cli_aliases shelduck_analyze_cli_command shelduck_analyze_cli_url shelduck_analyze_cli_args

	# restore state after recursive call
	shelduck_run_args="$1"

}




# fun: shelduck_analyze_cli [CLIARGS...]
shelduck_analyze_cli() {
	shelduck_parse_cli "$@"

	shelduck_analyze_cli_aliases="$shelduck_parse_cli_aliases"
	unset shelduck_parse_cli_aliases

	shelduck_analyze_cli_command="$shelduck_parse_cli_command"
	unset shelduck_parse_cli_command

	: "${shelduck_base_url:=${SHELDUCK_BASE_URL:-}}"
	if [ -n "$shelduck_parse_cli_url" ]; then
		shelduck_analyze_cli_url=$(bobshell_resolve_url "$shelduck_parse_cli_url" "$shelduck_base_url")
		unset shelduck_parse_cli_url
		if [ -n "${SHELDUCK_URL_RULES:-}" ]; then
			shelduck_analyze_cli_url=$(shelduck_apply_rules "$shelduck_analyze_cli_url" "$SHELDUCK_URL_RULES")
		fi
	else
		shelduck_analyze_cli_url="$shelduck_parse_cli_url"
		unset shelduck_parse_cli_url
	fi

	shelduck_analyze_cli_args="$shelduck_parse_cli_args"
	unset shelduck_parse_cli_args
}




# fun: shelduck_parse_cli [CLIARGS...]
# env: shelduck_parse_cli_aliases
#      shelduck_parse_cli_command
#      shelduck_parse_cli_url
#      shelduck_parse_cli_args
# api: private
shelduck_parse_cli() {
	bobshell_require_not_empty "${1:-}" 'at least one argument expected'
	shelduck_parse_cli_aliases=
	shelduck_parse_cli_command=
	shelduck_parse_cli_url=
	shelduck_parse_cli_args=
	while [ "${1+defined}" = defined ]; do
		bobshell_require_not_empty "${1:-}" "arg expected to be nonempty"
		case "$1" in
			-a|--alias)
				shift;
				if [ defined != "${1+defined}" ]; then
					bobshell_die 'alias argument expected'
				fi
				bobshell_require_not_empty "${1:-}" "alias argument expected to be not empty"
				shelduck_parse_cli_aliases="$shelduck_parse_cli_aliases $1"
				shift
				;;

			-c|--command)
				shift;
				if [ defined != "${1+defined}" ]; then
					bobshell_die 'command argument expected'
				fi
				bobshell_require_not_empty "${1:-}" "command argument expected to be not empty"
				shelduck_parse_cli_command="$1"
				shift
				;;

			*)
				if [ -z "${1:-}" ]; then
					bobshell_die "url expected to be nonempty"
				fi
				if [ -z "$shelduck_parse_cli_url" ]; then
					shelduck_parse_cli_url="$1"
					shift
					shelduck_parse_cli_args="$(bobshell_quote "$@")"
					break
				fi
				;;
		esac
	done

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
	eval "$shelduck_eval_with_args_script"
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
	shelduck_ensure_base_url
	
	# parse cli
	shelduck_analyze_cli "$@"
	bobshell_require_not_empty "${shelduck_analyze_cli_url:-}" "import: url must be defined" # since we checking for duplicates, url is mandatorry
	if [ -n "$shelduck_analyze_cli_command" ]; then
		bobshell_log "shelduck_import: warn: function makes no sence and hence ignored"
	fi
	if [ -n "$shelduck_analyze_cli_args" ]; then
		bobshell_log "shelduck_import: warn: args make no sence and hence ignored"
	fi

	# todo apply url rules

	# check for duplicates
	: "${shelduck_import_history:=}"
	if bobshell_contains "$shelduck_import_history" "$shelduck_analyze_cli_url"; then
		# todo maybe base url is needed
		shelduck_import_origin=$(shelduck_print_origin "$shelduck_analyze_cli_url")
		shelduck_import_addition=$(shelduck_print_addition "$shelduck_import_origin" "$shelduck_analyze_cli_url" "$shelduck_analyze_cli_aliases")
		eval "$shelduck_import_addition"
		unset shelduck_import_origin shelduck_import_addition
		return
	fi
	shelduck_import_history="$shelduck_import_history $shelduck_analyze_cli_url"
	
	# delegate to shelduck_exec
	shelduck_exec "$shelduck_analyze_cli_aliases" '' "$shelduck_analyze_cli_url" ''
	unset shelduck_analyze_cli_aliases shelduck_analyze_cli_command shelduck_analyze_cli_url shelduck_analyze_cli_args

}




# fun: shelduck_exec ALIASES COMMAND ABSURL ARGS
shelduck_exec() {
	shelduck_ensure_base_url


	# exec absurl ABSURL
	if [ -n "$3" ]; then
		shelduck_alias_strategy=wrap
		shelduck_exec_origin=$(shelduck_print_origin "$3")
		shelduck_exec_additions=$(shelduck_print_addition "$shelduck_exec_origin" "$3" "$1")

		# save state before recursive call
		set -- "$shelduck_base_url" "$1" "$2" "$3" "$4" shelduck_eval_with_args "$shelduck_exec_origin$shelduck_exec_additions"
		if [ -n "$5" ]; then
			eval "set -- \"\$@\" $5"
		fi
		
		# recursive call
		shelduck_base_url=$(bobshell_base_url "$4")
		shelduck_shift_exec 5 "$@"

		# restore state after recursive call
		shelduck_base_url="$1"
		shift
	fi
	
	if [ -n "$2" ]; then
		# save state before recursive call
		set -- "$shelduck_base_url" "$1" "$2" "$3" "$4" shelduck_eval_with_args "$2"
		if [ -n "$5" ]; then
			eval "set -- \"\$@\" $5"
		fi

		# recursive command
		shelduck_base_url=$(bobshell_base_url "$4")
		shelduck_shift_exec 5 "$@"

		# restore state after recursive call
		shelduck_base_url="$1"
	fi

}

# fun: shelduck_shift_exec SHIFTNUM IGNORED ... COMMAND [ARGS...]
shelduck_shift_exec() {
	shift "$1"
	shift
	"$@"
}



# api: private
shelduck_usage() {
	printf 'Usage: shelduck SUBCOMMAND [ARGS...]\n'
	printf 'Subcommands are:\n'
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

	shelduck_print_initial_base_url="$shelduck_base_url"

	# parse cli
	shelduck_analyze_cli "$@"
	if [ -n "$shelduck_analyze_cli_command" ]; then
		bobshell_log "warn: function makes no sence and hence ignored"
	fi
	unset shelduck_analyze_cli_command
	bobshell_require_not_empty "$shelduck_analyze_cli_url" 'cli url is required'
	if [ -n "$shelduck_analyze_cli_args" ]; then
		bobshell_log "warn: url arguments make no sence and hence ignored"
	fi
	unset shelduck_analyze_cli_args

	# load script
	shelduck_print_script=$(shelduck_print_origin "$shelduck_analyze_cli_url")
	
	# save variables to local array before subsequent (possibly recursive) calls
	set -- "$shelduck_print_script" "$shelduck_analyze_cli_url" "$shelduck_analyze_cli_aliases" "$shelduck_base_url" "$shelduck_print_initial_base_url"

	# check if dependency was already compiled
	if ! bobshell_contains "$shelduck_print_history" "$2"; then
		shelduck_print_history="$shelduck_print_history $2"

		shelduck_base_url=$(bobshell_base_url "$shelduck_analyze_cli_url")

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




# fun: shelduck_compile SCRIPT
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




# fun: shelduck_rewrite ORIGCONTENT
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
shelduck_cached_fetch_url() {
	# bypass cache if local file
	if bobshell_remove_prefix "$1" 'file://' file_name; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		if ! [ -f "$file_name" ]; then
			bobshell_die "shelduck: fetch error '$1': file '$file_name' not found"
		fi
		cat "$file_name" || bobshell_die "shelduck: fetch error '$1': error loading '$file_name'"
		unset file_name
		return
	fi
	# todo implement cache
	# todo timeout
	bobshell_fetch_url "$1" || bobshell_die "shelduck: fetch error '$1': error downloading '$1'"
}


# disable recursive dependency resolution when building shelduck itself
# shelduck import string.sh

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



# STRING MANUPULATION

# disable recursive dependency resolution when building shelduck itself
# shelduck import base.sh



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
	elif   bobshell_remove_prefix "$1" file:// bobshell_resolve_url_path; then
		bobshell_resolve_url_path=$(realpath "$bobshell_resolve_url_path")
		printf 'file://%s' "$bobshell_resolve_url_path"
	elif bobshell_starts_with "$1" http:// \
	  || bobshell_starts_with "$1" https:// \
	  || bobshell_starts_with "$1" ftp:// \
	  || bobshell_starts_with "$1" ftps:// \
			; then
		printf %s "$1"
	else
		bobshell_resolve_url_base="${2:-}"
		if [ -z "$bobshell_resolve_url_base" ]; then
			bobshell_resolve_url_base=$(pwd)
		fi
		printf %s "$bobshell_resolve_url_base"
		if ! bobshell_ends_with "$bobshell_resolve_url_base" /; then
			printf '/'
		fi
		# todo handle ..
		bobshell_resolve_url_value="$1"
		while bobshell_remove_prefix "$bobshell_resolve_url_value" './' bobshell_resolve_url_value; do
			true
		done
		printf %s "$bobshell_resolve_url_value"
		unset bobshell_resolve_url_value
	fi
}

bobshell_fetch_url_with_curl() {
	curl --fail --silent --show-error --location "$1"
}

bobshell_fetch_url_with_wget() {
	wget --no-verbose --output-document -
}


