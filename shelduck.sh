


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/log.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/install.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_file.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_remote.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_stdin.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_stdout.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/parse.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/file_date.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/resource/copy.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/scope.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/url.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/util.sh



# see https://github.com/ajdiaz/bashdoc


# global vars:
# shelduck_base_url
# shelduck_import_history
#
#
#

# fun: shelduck CLIARGS...
# api: public
# env: SHELDUCK_BASE_URL
#      SHELDUCK_LIBRARY_PATH
#      SHELDUCK_URL_RULES
shelduck() {
	bobshell_require_not_empty "${1:-}" 'shelduck: subcommad expected, see shelduck usage'
	case "$1" in
		(usage|run|build|resolve|import|fetch)
			: # ok run subcommand
			;;

		(*)
			printf 'unknown subcommand %s, see shelduck usage' "$1"
			return 1
			;;
	esac

	shelduck_alias_strategy=wrap
	_shelduck__subcommand="$1"
	shift
	"shelduck_$_shelduck__subcommand" "$@"

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



# global variables
# shelduck_base_url
# shelduck_compile_history ?
# shelduck_import_history ?



# fun: shelduck_run URL [ARGS...]
# api: private
# env: shelduck_run_args
shelduck_run() {
	# parse cli
	if ! [ $# -ge 1 ]; then
		bobshell_die '"shelduck run" requires at least 1 argument'
	fi

	shelduck_ensure_base_url
	_shelduck_run__orig_base_url="$shelduck_base_url"

	_shelduck_run__url="$1"
	shift

	bobshell_str_quote "$@"
	shelduck_run_args="$bobshell_result_1"

	# load script
	shelduck_do_fetch "$_shelduck_run__url"
	bobshell_result_assert _shelduck_run__script -- shelduck_do_fetch failed

	shelduck_transform "$_shelduck_run__script" "$_shelduck_run__url"
	bobshell_result_assert _shelduck_run__script -- shelduck_transform failed

	set -- shelduck_eval_with_args "$_shelduck_run__script" "$@"
	unset _shelduck_run__script

	# save state before recursive call
	set -- "$_shelduck_run__orig_base_url" "$@"


	# recursive call (no need to save state)
	shelduck_update_base_url "$3"
	unset _shelduck_run__url
	bobshell_shift_exec 1 "$@"

	# restore state after recursive call
	unset shelduck_base_url
	if [ -n "$_shelduck_run__orig_base_url" ]; then
		shelduck_base_url="$_shelduck_run__orig_base_url"
	fi
}




# shelduck_build URL
# api: public
# build -> compile -> process_imports -> compile ...
shelduck_build() {
	shelduck_ensure_base_url


	# save state
	set -- "${shelduck_compile_history:-}" "${shelduck_base_url:-}" shelduck_compile "$@"

	# recursive call
	_shelduck_compile_history=
	shelduck_shift_exec 2 "$@"

	# restore state
	unset shelduck_compile_history
	if [ -n "$1" ]; then
		shelduck_compile_history="$1"
	fi
	unset shelduck_base_url
	if [ -n "$2" ]; then
		shelduck_base_url="$2"
	fi

	bobshell_result_assert -- 'shelduck build failed'
	printf %s "$bobshell_result_2"
	# shift 2
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




shelduck_fix_url() {
	if [ -z "$1" ]; then
		bobshell_die "shelduck: invalid url"
	fi

	shelduck_ensure_base_url

	if bobshell_starts_with "$1" path://; then
		shelduck_path_search "$1"
		bobshell_result_assert _shelduck_fix_url__result -- cannot find resource by url "$1"
		bobshell_result_set "$_shelduck_fix_url__result"
		unset _shelduck_fix_url__result
	elif bobshell_locator_is_remote "$1" || bobshell_locator_is_file "$1" || ! bobshell_locator_parse "$1"; then
		shelduck_fix_url=$(bobshell_resolve_url "$1" "$shelduck_base_url")
		if [ -n "${SHELDUCK_URL_RULES:-}" ]; then
			shelduck_fix_url=$(shelduck_apply_rules "$shelduck_fix_url" "$SHELDUCK_URL_RULES")
		fi

		bobshell_result_set "$shelduck_fix_url"
		unset shelduck_fix_url
	else
		bobshell_result_set "$1"
	fi
}

# fun: shelduck_path_search URL
shelduck_path_search() {
	if bobshell_isset SHELDUCK_PATH; then
		_shelduck_path_search__path="$SHELDUCK_PATH"
	else
		_shelduck_path_search__path="${XDG_DATA_HOME:-$HOME/.local/share}/shelduck/lib}"
	fi

	if [ -z "$_shelduck_path_search__path" ]; then
		unset _shelduck_path_search__path
		bobshell_result_set false "file $1 not found in empty path"
		return
	fi

	bobshell_str_split_v2 "$SHELDUCK_PATH" :
	for i in $(seq "$bobshell_result_size"); do
		x=$(bobshell_var_print bobshell_result_"$i")
		if [ -f "$x"/"$1" ]; then
			unset i x _shelduck_path_search__path
			bobshell_result_set true "$x"/"$1"
			return
		fi
	done

	unset i x _shelduck_path_search__path
	bobshell_result_set false "file $1 not found in path $_shelduck_path_search__path"
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





# shelduck_run and shelduck_import are very similar, but:
# - import requires url, since it checks for duplicates, whereas run does not requies url
# - import checks for duplicate urls, run not
# - import takes args from run_args
# - run takes args from command, and restores


# fun: shelduck_import CLIARGS...
# api: public
# env: shelduck_base_url
shelduck_import() {
	shelduck_ensure_base_url

	shelduck_parse_import_cli "$@"

	shelduck_fix_url "$shelduck_import_url"
	shelduck_import_url="$bobshell_result_1"

	shelduck_do_fetch "$shelduck_import_url"
	bobshell_result_assert _shelduck_import__script -- fetch failed

	shelduck_transform "$_shelduck_import__script" "$shelduck_import_url"
	bobshell_result_assert _shelduck_import__script -- apply transformation to module "$shelduck_import_url" failed

	#
	shelduck_print_addition  "$_shelduck_import__script" "$shelduck_import_url" "$shelduck_import_aliases"
	bobshell_result_assert _shelduck_import__add_script -- print addition failed
	if [ -n "$_shelduck_import__add_script" ]; then
		_shelduck_import__add_script="
$_shelduck_import__add_script
"
	fi

	# check for duplicates
	: "${shelduck_import_history:=}"
	if bobshell_contains "$shelduck_import_history" "[$shelduck_import_url]"; then
		_shelduck_import__script="$_shelduck_import__add_script"
	else
		shelduck_import_history="$shelduck_import_history [$shelduck_import_url]"
		_shelduck_import__script="$_shelduck_import__script$_shelduck_import__add_script"
	fi
	unset _shelduck_import__add_script


	if [ -z "$_shelduck_import__script" ]; then
		return
	fi


	# save state before recursive call
	set -- "$shelduck_base_url" eval "$_shelduck_import__script"

	# recursive call
	shelduck_update_base_url "$shelduck_import_url"
	shelduck_eval_with_args "$_shelduck_import__script"

	# restore state after recursive call
	shelduck_base_url="$1"
	shift

}

# fun: shelduck_transform SCRIPTTEXT [ ABSURL ]
# txt: make transformation of module src regardless of context, the result of transform can be cached
shelduck_transform() {
	_shelduck_transform__script="$1"
	shift

	# maybe write comment at the beginning of result
	if bobshell_starts_with "${1:-}" file:// https:// http:// stdin:; then
		if bobshell_starts_with "$_shelduck_transform__script" "$bobshell_newline"; then
			_shelduck_transform__script='

# shelduck: script '"$1"'
'"$_shelduck_transform__script"'
# shelduck: end of script '"$1"'

'
		fi
	fi

	set -- "$_shelduck_transform__script" "$@"
	unset _shelduck_transform__script

	bobshell_event_fire shelduck_transform_event "$@"

	bobshell_result_set true "$1"
}

# fun: shelduck_compile URL
# api: private
# env: shelduck_base_url
# env: shelduck_compile_history
# txt: exported with build
shelduck_compile() {

	shelduck_parse_import_cli "$@"
	shelduck_fix_url "$shelduck_import_url"
	_shelduck_compile_url="$bobshell_result_1"
	unset shelduck_import_url

	_shelduck_compile_aliases="$shelduck_import_aliases"
	unset shelduck_import_aliases

	# # todo is _shelduck_compile_initial_base_url needed?




	# load script
	shelduck_do_fetch "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- shelduck_do_fetch failed

	shelduck_transform "$_shelduck_compile_script" "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- shelduck_transform failed

	shelduck_event_url "$_shelduck_compile_url" "$_shelduck_compile_script"

	shelduck_print_addition  "$_shelduck_compile_script" "$_shelduck_compile_url" "$_shelduck_compile_aliases"
	bobshell_result_assert _shelduck_compile_add_script -- print addition failed

	if [ -n "$_shelduck_compile_add_script" ]; then
		_shelduck_import__add_script="
# additions for $_shelduck_compile_url ($_shelduck_compile_aliases)
$_shelduck_compile_add_script
# end of additions for $_shelduck_compile_url

"
fi


	if bobshell_contains "$_shelduck_compile_history" "[$_shelduck_compile_url]"; then
		_shelduck_compile_script="
# skip script $_shelduck_compile_url (already compiled)
$_shelduck_compile_add_script"
	else
		_shelduck_compile_history="$_shelduck_compile_history [$_shelduck_compile_url]"
		_shelduck_compile_script="$_shelduck_compile_script$_shelduck_compile_add_script"
	fi
	unset _shelduck_compile_add_script

	if [ -z "$_shelduck_compile_script" ]; then
		bobshell_result_set true "$_shelduck_compile_script"
		return
	fi

	# save state before recursive call
	set -- "$shelduck_base_url" "$@"

	# recursive calls
	shelduck_update_base_url "$_shelduck_compile_url"
	shelduck_parse_commands "$_shelduck_compile_script" "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- process_imports failed

	# restore state
	unset shelduck_base_url
	if [ -n "$1" ]; then
		shelduck_base_url="$1"
	fi
	# shift

	bobshell_result_set true "$_shelduck_compile_script"
	unset _shelduck_compile_script

}






# fun: shelduck_apply_imports CODESCRIPT URL
# res: true  REWRITTENSCRIPT
# res: false error message
shelduck_parse_commands() {
	_shelduck_parse_commands__input="$1"
	shift

	# iterate over all shelduck imports in input script
	_shelduck_parse_commands__result=
	while [ -n "$_shelduck_parse_commands__input" ]; do
		bobshell_str_split_v2 "$_shelduck_parse_commands__input" 'shelduck ' 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			break
		fi
		_shelduck_parse_commands__input="$bobshell_result_2"

		# check for supported subcommands
		if bobshell_starts_with "$_shelduck_parse_commands__input" 'import '; then
			: # ok, continue
		elif bobshell_starts_with "$_shelduck_parse_commands__input" 'fetch '; then
			: # ok, continue
		else # unsupported command, skip
			bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"'shelduck '
			continue
		fi

		# check for indentation
		if [ -n "$bobshell_result_1" ] && ! bobshell_ends_with "$bobshell_result_1" "$bobshell_newline"; then
			# command is indentated, skip
			bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"'shelduck '
			continue
		fi

		bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_1"
		_shelduck_parse_commands__command=
		while true; do
			bobshell_str_split_v2 "$_shelduck_parse_commands__input" "${bobshell_newline}" 2
			if [ "$bobshell_result_size" -lt 2 ]; then
				bobshell_var_append _shelduck_parse_commands__command "$bobshell_result_1"
				_shelduck_parse_commands__input=
				break
			fi

			_shelduck_parse_commands__candidate="$bobshell_result_1"
			_shelduck_parse_commands__input="$bobshell_result_2"

			bobshell_str_suffix "$_shelduck_parse_commands__candidate" '\'
			if bobshell_result_check; then
				bobshell_var_append _shelduck_parse_commands__command "$bobshell_result_2 "
			else
				_shelduck_parse_commands__input="$bobshell_newline$_shelduck_parse_commands__input"
				bobshell_var_append _shelduck_parse_commands__command "$_shelduck_parse_commands__candidate"
				break
			fi
			unset _shelduck_parse_commands__candidate

		done
		if [ -z "$_shelduck_parse_commands__command" ]; then
			bobshell_die empty command
		fi

		# save state before recursive call
		set -- "$_shelduck_parse_commands__result" "$_shelduck_parse_commands__input" "$_shelduck_parse_commands__command" "$@"
		unset    _shelduck_parse_commands__result    _shelduck_parse_commands__input

		shelduck_process_command $_shelduck_parse_commands__command

		# restore state after recursive all
		_shelduck_parse_commands__result="$1"
		_shelduck_parse_commands__input="$2"
		_shelduck_parse_commands__command="$3"
		shift 3

		# accumulate result of recursive call
		bobshell_result_assert -- error processing "$_shelduck_parse_commands__command"
		bobshell_var_append _shelduck_parse_commands__result "$bobshell_result_2"

		unset _shelduck_parse_commands__command
	done

	# accumulate the rest of script after last shelcuk import
	bobshell_var_append _shelduck_parse_commands__result "$_shelduck_parse_commands__input"
	unset _shelduck_parse_commands__input

	# return result
	bobshell_result_set true "$_shelduck_parse_commands__result"
	unset _shelduck_parse_commands__result
}




shelduck_process_command() {
	case "$1" in
		(import)
			shift
			shelduck_compile "$@"
			;;

		(fetch)
			shift
			shelduck_fetch "$@"
			;;

		(*)
			bobshell_result_set false unsupported command "$1"
			;;
	esac
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



# DEPRECATED
# fun: shelduck_resolve URL [ ARGS ... ]
# api: public
shelduck_resolve() {
	bobshell_log_warn 'shelduck: resolve is deprecated, use build instead'
	shelduck_build "$@"
}




shelduck_fetch() {
	if [ $# != 1 ]; then
		bobshell_die shelduck_fetch: exactly one argument expected
	fi
	shelduck_fix_url "$1"
	shelduck_do_fetch "$bobshell_result_1"
}

# fun: shelduck_do_fetch ABSURL
# txt: prints original script without modification
# api: private
shelduck_do_fetch() {
	bobshell_result_set false
	bobshell_event_fire shelduck_do_fetch_url_event "$1"
	if bobshell_result_check; then
		bobshell_result_set true "$bobshell_result_2"
		return
	fi
	shelduck_cached_fetch_url "$1"
	bobshell_result_set true "$bobshell_result_1"
}




# fun: shelduck_print_addition ORIGCONTENT ABSURL ALIASES
# txt: print script additional code (e.g. aliases)
# api: private
shelduck_print_addition() {

	if [ wrap != "${shelduck_alias_strategy:-}" ]; then
		# nothing to do, wrap was the only supported customization
		bobshell_result_set true ''
		return
	fi

	# analyze functions (for aliases)
	regex='^ *([A-Za-z0-9_]+) *\( *\) *\{ *$' # match shell function declaration '  function_name  (   )  {  '
	shelduck_print_addition_function_names="$(printf %s "$1" | sed --silent --regexp-extended "s/$regex/\1/p")"
	unset regex
	# todo detect function name collizion and print warning if so


	# analyze aliases
	_shelduck_print_addition=
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
			_shelduck_print_addition="$_shelduck_print_addition"'

# shelduck: alias for '"$shelduck_print_script_function_name"' (from '"$2"')
'"$key"'() {
	'"$shelduck_print_script_function_name"' "$@"
}
'
		fi
		unset key value shelduck_print_script_function_name
	done
	unset shelduck_print_addition_function_names

	bobshell_result_set true "$_shelduck_print_addition"
	unset _shelduck_print_addition
}















########################
######### FETCH ########
########################

# fun: shelduck_cached_fetch_url ABSURL
# txt: download dependency given url and save to cache
# api: private
shelduck_cached_fetch_url() {
	# bypass cache if local file
	if bobshell_locator_is_file "$1" shelduck_cached_fetch_url_path; then
		bobshell_cache_get --ttl=60 "shelduck_cached_fetch_url/$1" shelduck_cached_fetch_file "$shelduck_cached_fetch_url_path"
		unset shelduck_cached_fetch_url_path
	elif bobshell_locator_is_remote "$1"; then
		bobshell_cache_get --ttl=60 "shelduck_cached_fetch_url/$1" shelduck_cached_fetch_remote "$1"
	else
		bobshell_resource_copy "$1" var:_shelduck_cached_fetch_url
		bobshell_result_set "$_shelduck_cached_fetch_url"
		unset _shelduck_cached_fetch_url
	fi
}

# fun: shelduck_cached_fetch_file FILEPATH
shelduck_cached_fetch_file() {
	if ! [ -f "$1" ]; then
		bobshell_die "shelduck: fetch error '$1': file '$1' not found"
	fi
	bobshell_resource_copy_file_to_var "$1" _shelduck_cached_fetch_file
	bobshell_result_set "$_shelduck_cached_fetch_file"
	unset _shelduck_cached_fetch_file
}

# fun: shelduck_cached_fetch_remote FILEPATH
shelduck_cached_fetch_remote() {
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
			_shelduck_cached_fetch_url__timestamp=$(( _shelduck_cached_fetch_url__timestamp + ${SHELDUCK_CACHE_TIMEOUT:-86400} ))
			_shelduck_cached_fetch_url__now=$(date '+%s')

			if [ "$_shelduck_cached_fetch_url__now" -lt "$_shelduck_cached_fetch_url__timestamp" ]; then
				bobshell_resource_copy_file_to_var "$shelduck_cached_fetch_url_path" _shelduck_cached_fetch_remote__data
				bobshell_result_set "$_shelduck_cached_fetch_remote__data"
				unset shelduck_cached_fetch_url_path _shelduck_cached_fetch_url__timestamp _shelduck_cached_fetch_url__now _shelduck_cached_fetch_remote__data
				return
			fi
			unset _shelduck_cached_fetch_url__timestamp _shelduck_cached_fetch_url__now
		fi
		unset shelduck_cached_fetch_url_path
	fi

	shelduck_cached_fetch_url_result=$(bobshell_fetch_url "$1" || bobshell_die "shelduck: fetch error '$1': error downloading '$1'")

	bobshell_install_put_cache var:shelduck_cached_fetch_url_result "$shelduck_cached_fetch_url_key"
	bobshell_result_set "$shelduck_cached_fetch_url_result"
}
