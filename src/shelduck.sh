


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/log.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/event/fire.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/event/listen.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/event/stop.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/install.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_file.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_remote.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_stdin.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/is_stdout.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/locator/parse.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/file_date.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/resource/copy.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/assert.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/scope.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/string.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/quote.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/url.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/util.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/prefix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/cache/get.sh

shelduck import ./util.sh
shelduck import ./url.sh
shelduck import ./cache.sh
shelduck import ./import.sh
shelduck import ./transform.sh
shelduck import ./deprecated.sh

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
	shelduck_alias_strategy=wrap # todo fix
	bobshell_require_not_empty "${1:-}" 'shelduck: subcommad expected, see shelduck usage'
	case "$1" in

		(import|fetch) # only at runtime within scripts
			shelduck_subcommand "$@"
			;;

		(usage|run|build|resolve) # compile time
			shelduck_subcommand "$@"
			;;

		(preprocess) # not a command rather a compiler directive
			bobshell_die "shelduck $1 is available only in compile-time, not runtime"
			;;

		(*)
			bobshell_die 'unknown subcommand %s, see shelduck usage' "$1"
			;;
	esac
}

shelduck_init() {
	shelduck_cache_ttl="${SHELDUCK_FILE_CACHE_TTL:-3600}"

	shelduck_cache_dir="${SHELDUCK_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/shelduck}"
	mkdir -p "$shelduck_cache_dir/remote" "$shelduck_cache_dir/transform"
}

shelduck_init

shelduck_subcommand() {
	_shelduck_subcommand="$1"
	shift
	set -- "shelduck_$_shelduck_subcommand" "$@"
	unset _shelduck_subcommand
	"$@"
}


# api: private
shelduck_usage() {
	printf %s 'Usage: shelduck SUBCOMMAND [ARGS...]
Commands:
    usage
    import
    resolve
    run
'
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


	shelduck_fix_url "$1"
	_shelduck_run__url="$bobshell_result_1"
	shift

	bobshell_str_quote "$@"
	shelduck_run_args="$bobshell_result_1"

	# load script
	shelduck_prepare "$_shelduck_run__url"
	bobshell_result_assert _shelduck_run__script -- shelduck_run: shelduck_prepare failed

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

	bobshell_result_assert _shelduck_build__result -- 'shelduck build failed'

	bobshell_str_prefix "$_shelduck_build__result" '#!/usr/bin/env shelduck_run'"$bobshell_newline"
	if bobshell_result_check; then
		_shelduck_build__result='#!/bin/sh'"$bobshell_newline$bobshell_result_2"
	fi

	printf %s "$_shelduck_build__result"
	# shift 2
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











# fun: shelduck_prepare ABSURL
shelduck_prepare() {
	if bobshell_locator_is_remote "$1"; then
		shelduck_cache_get transform "$1"
		if bobshell_result_check; then
			return
		fi
		_shelduck_prepare__cached=true
	elif bobshell_locator_is_file "$1" _shelduck_prepare__file; then
		shelduck_cache_fget transform "$_shelduck_prepare__file"
		unset _shelduck_prepare__file
		if bobshell_result_check; then
			return
		fi
		_shelduck_prepare__cached=true
	else
		_shelduck_prepare__cached=false
	fi

	shelduck_do_fetch "$1"
	bobshell_result_assert -- shelduck_prepare: fetch failed

	shelduck_transform "$bobshell_result_2" "$1"
	if bobshell_result_check _shelduck_prepare__result; then
		if shelduck_str_equals cached "$_shelduck_prepare__cached"; then
			shelduck_cache_put transform "$1" "$_shelduck_prepare__result"
		fi
		bobshell_result_set_2 true "$_shelduck_prepare__result"
		unset _shelduck_prepare__result
	fi
	unset _shelduck_prepare__cached
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
	shelduck_prepare "$_shelduck_compile_url"
	bobshell_result_assert _shelduck_compile_script -- shelduck_compile: prepare failed

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

shelduck_compile_command_listener() {

	# shelduck preprocess replace %%_ com_legeyda_bobshell_

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'import '
	if bobshell_result_check _shelduck_parse_commands__command; then
		shelduck_compile "$_shelduck_parse_commands__command"
		bobshell_result_assert
		bobshell_result_set true apply "$bobshell_result_2"
	fi

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'fetch '
	if bobshell_result_check _shelduck_parse_commands__command; then
		shelduck_fetch "$_shelduck_parse_commands__command"
		break # todo
	fi

	bobshell_str_prefix "$_shelduck_parse_commands__command" 'transform '
	if bobshell_result_check _shelduck_parse_commands__command; then
		bobshell_die transform unsupported in compile mode
	fi


	bobshel_result_set true skip
	_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
	unset _shelduck_parse_commands__command
	break


}

shelduck_process_compile_commands() {
	_shelduck_parse_commands__input="$1"
	shift
	_shelduck_parse_commands__result=
	while true; do
		shelduck_next_command "$_shelduck_parse_commands__input"
		if bobshell_result_check; then
			_shelduck_parse_commands__result="$_shelduck_parse_commands__result$bobshell_result_2"
			_shelduck_parse_commands__command="$bobshell_result_3"
			_shelduck_parse_commands__input="$bobshell_result_4"

			bobshell_str_prefix "$_shelduck_parse_commands__command" 'shelduck '
			bobshell_result_assert _shelduck_parse_commands__command -- command parse failed

			bobshell_str_replace "$_shelduck_parse_commands__command" '\'"$bobshell_newline" ' '
			bobshell_result_assert - _shelduck_parse_commands__command

			"$@" "$_shelduck_parse_commands__result" "$_shelduck_parse_commands__command" "$_shelduck_parse_commands__input"

			bobshell_result_assert  -- parse failed
			if [ apply = "$bobshell_result_2" ]; then
				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$bobshell_result_3"
			elif [ skip = "$bobshell_result_2" ]; then
				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
			else
				bobshell_die 'shelduck_parse_commands: unsupported result from listener ('"$bobshell_result_2"')'
			fi


			while true; do
				bobshell_str_prefix "$_shelduck_parse_commands__command" 'import '
				if bobshell_result_check _shelduck_parse_commands__command; then
					shelduck_compile "$_shelduck_parse_commands__command"
				fi

				bobshell_str_prefix "$_shelduck_parse_commands__command" 'fetch '
				if bobshell_result_check _shelduck_parse_commands__command; then
					shelduck_fetch "$_shelduck_parse_commands__command"
					break # todo
				fi

				bobshell_str_prefix "$_shelduck_parse_commands__command" 'transform '
				if bobshell_result_check _shelduck_parse_commands__command; then
					bobshell_die transform unsupported in compile mode
				fi

				_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__command"
				unset _shelduck_parse_commands__command
				break
			done
		else
			_shelduck_parse_commands__result="$_shelduck_parse_commands__result$_shelduck_parse_commands__input"
			break
		fi
	done

	unset _shelduck_parse_commands__input
	bobshell_result_set true "$_shelduck_parse_commands__result"
	unset _shelduck_parse_commands__result
}



# fun: shelduck_next_command INPUT
# res: true SKIP COMMAND REST
# res: false
shelduck_next_command() {
	if [ -z "$1" ]; then
		bobshell_result_set false
		return
	fi

	_shelduck_next_command__rest="$1"
	shift

	# search for next unindented shelduck command
	_shelduck_next_command__skip=
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" 'shelduck ' 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			unset _shelduck_next_command__rest _shelduck_next_command__skip
			bobshell_result_set false
			return
		fi
		_shelduck_next_command__rest="$bobshell_result_2"

		# check for indentation
		if [ -n "$bobshell_result_1" ] && ! bobshell_ends_with "$bobshell_result_1" "$bobshell_newline"; then
			# command is indentated, skip
			bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"'shelduck '
			continue
		fi

		bobshell_var_append _shelduck_next_command__skip "$bobshell_result_1"
		break
	done

	# trace command to multiple lines
	_shelduck_next_command__command='shelduck '
	while true; do
		bobshell_str_split_v2 "$_shelduck_next_command__rest" "${bobshell_newline}" 2
		if [ "$bobshell_result_size" -lt 2 ]; then
			bobshell_var_append _shelduck_next_command__command "$bobshell_result_1"
			bobshell_result_set true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" ''
			break
		fi

		_shelduck_next_command__candidate="$bobshell_result_1"
		_shelduck_next_command__rest="$bobshell_result_2"

		bobshell_str_suffix "$_shelduck_next_command__candidate" '\'
		if bobshell_result_check; then
			unset _shelduck_next_command__candidate
			bobshell_var_append _shelduck_next_command__command "$bobshell_result_2"'\'"$bobshell_newline"
			continue
		else
			_shelduck_next_command__rest="$bobshell_newline$_shelduck_next_command__rest"
			bobshell_var_append _shelduck_next_command__command "$_shelduck_next_command__candidate"
			bobshell_result_set true "$_shelduck_next_command__skip" "$_shelduck_next_command__command" "$_shelduck_next_command__rest"
			break
		fi
	done
	unset _shelduck_next_command__skip _shelduck_next_command__command _shelduck_next_command__rest
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
		# todo
		# bobshell_str_math "$_shelduck_parse_commands__input" '"import "*'
		# if bobshell_result_check
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

	if bobshell_locator_is_remote "$1"; then
		shelduck_cache_get remote "$1"
		if bobshell_result_check; then
			return
		fi
		_shelduck_do_fetch__result=$(bobshell_fetch_url "$1")
		shelduck_cache_put remote "$1" "$_shelduck_do_fetch__result"
	elif bobshell_locator_is_file "$1"; then
		shelduck_mcache_get file "$1"
		if bobshell_result_check; then
			return
		fi
		bobshell_resource_copy "$1" var:_shelduck_do_fetch__result
		shelduck_mcache_put file "$1" "$_shelduck_do_fetch__result"
	else
		bobshell_resource_copy "$1" var:_shelduck_do_fetch__result
	fi

	bobshell_result_set_2 true "$_shelduck_do_fetch__result"
	unset _shelduck_do_fetch__result
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
