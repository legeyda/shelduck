
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

	# если нет допаргументов и уже импортировали (что скорее всего), можно пропустить вообще и даже не парсить
	: "${shelduck_import_history:=}"
	if [ "$#" = 1 ]; then
		shelduck_fix_url "$1"
		shelduck_import_url="$bobshell_result_1"
		shelduck_import_aliases=
		if bobshell_contains "$shelduck_import_history" "[$shelduck_import_url]"; then
			return
		fi
	else
		shelduck_parse_import_cli "$@"
		shelduck_fix_url "$shelduck_import_url"
		shelduck_import_url="$bobshell_result_1"
	fi



	shelduck_prepare "$shelduck_import_url"
	bobshell_result_assert _shelduck_import__script -- shelduck_import: prepare failed: "$1"

	#
	shelduck_print_addition  "$_shelduck_import__script" "$shelduck_import_url" "$shelduck_import_aliases"
	bobshell_result_assert _shelduck_import__add_script -- print addition failed
	if [ -n "$_shelduck_import__add_script" ]; then
		_shelduck_import__add_script="
$_shelduck_import__add_script
"
	fi

	# check for duplicates
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
