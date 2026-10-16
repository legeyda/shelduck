

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


# fun: shelduck_update_base_url URL
shelduck_update_base_url() {
	if bobshell_locator_is_file "$1" || bobshell_locator_is_remote "$1"; then
		shelduck_base_url=$(bobshell_base_url "$1")
	fi
}
