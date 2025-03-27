


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/install.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/is_file.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/is_remote.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/is_stdin.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/is_stdout.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/locator/parse.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/misc/file_date.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/resource/copy.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/scope.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/url.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/util.sh



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
				_shelduck__subcommand="$1"
				shift
				"shelduck_$_shelduck__subcommand" "$@"
				unset _shelduck__subcommand
				;;
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
	if bobshell_contains "$shelduck_import_history" "[$shelduck_import_url]"; then
		# todo maybe base url is needed
		shelduck_import_origin=$(shelduck_print_origin "$shelduck_import_url")
		shelduck_import_addition=$(shelduck_print_addition "$shelduck_import_origin" "$shelduck_import_url" "$shelduck_import_aliases")
		eval "$shelduck_import_addition"
		unset shelduck_import_origin shelduck_import_addition
		return
	fi
	shelduck_import_history="$shelduck_import_history [$shelduck_import_url]"
	
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
	if ! bobshell_contains "$shelduck_print_history" "[$2]"; then
		shelduck_print_history="$shelduck_print_history [$2]"

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
		if bobshell_starts_with "$1" file:// https:// http:// stdin:; then
			printf '%s\n' "# shelduck: source for $1"
		fi
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
	if bobshell_locator_is_file "$1" shelduck_cached_fetch_url_path; then
		# shellcheck disable=SC2154
		# starts_with sets variable file_name indirectly
		if ! [ -f "$shelduck_cached_fetch_url_path" ]; then
			bobshell_die "shelduck: fetch error '$1': file '$shelduck_cached_fetch_url_path' not found"
		fi
		cat "$shelduck_cached_fetch_url_path" || bobshell_die "shelduck: fetch error '$1': error loading '$shelduck_cached_fetch_url_path'"
		unset shelduck_cached_fetch_url_path
		return
	elif bobshell_locator_is_remote "$1"; then

		# init bobshell_install_* library
		: "${SHELDUCK_INSTALL_NAME:=shelduck}"
		bobshell_scope_mirror SHELDUCK_INSTALL_ BOBSHELL_INSTALL_
		bobshell_install_init

		# key
		shelduck_cached_fetch_url_key=$(printf %s "$1" | sed 's/[\/<>:\\|?*]/-/g')


		shelduck_cached_fetch_url_path=
		if shelduck_cached_fetch_url_path=$(bobshell_install_find_cache "$shelduck_cached_fetch_url_key"); then
			bobshell_file_date --format %s "$shelduck_cached_fetch_url_path"
			if bobshell_result_check _shelduck_cached_fetch_url__timestamp; then
				_shelduck_cached_fetch_url__timestamp=$(( _shelduck_cached_fetch_url__timestamp + ${SHELDUCK_CACHE_TIMEOUT:-3600} ))
				_shelduck_cached_fetch_url__now=$(date '+%s')
				
				if [ "$_shelduck_cached_fetch_url__now" -lt "$_shelduck_cached_fetch_url__timestamp" ]; then
					# todo expiration
					cat "$shelduck_cached_fetch_url_path"
					unset shelduck_cached_fetch_url_path _shelduck_cached_fetch_url__timestamp _shelduck_cached_fetch_url__now
					return
				fi
				unset _shelduck_cached_fetch_url__timestamp _shelduck_cached_fetch_url__now
			fi
			unset shelduck_cached_fetch_url_path
		fi
		
		shelduck_cached_fetch_url_result=$(bobshell_fetch_url "$1" || bobshell_die "shelduck: fetch error '$1': error downloading '$1'")

		bobshell_install_put_cache var:shelduck_cached_fetch_url_result "$shelduck_cached_fetch_url_key"
		printf %s "$shelduck_cached_fetch_url_result"
	else
		bobshell_resource_copy "$1" stdout:
	fi

)
