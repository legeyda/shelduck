


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/lstrip.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/prefix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/suffix.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/match.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/split_v3.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/append.sh

shelduck transform replace heredoc shelduck_parse_heredoc
shelduck transform replace bstr bobshell_str
shelduck transform replace bres bobshell_result


# fun: heredoc INPUT
# res: true VALUE NEXT
heredoc() {
	bstr_lstrip "$1" ' '
	_heredoc="$bres_2"

	bstr_prefix "$_heredoc" '<<'
	if ! bres_check _heredoc; then
		unset _heredoc _heredoc__input
		bres_set_2 false '"<<" expected'
		return
	fi


	bstr_split_v3 "$_heredoc" "$bobshell_newline"
	if ! bres_check _heredoc _heredoc__input; then
		unset _heredoc _heredoc__input
		bres_set_2 false 'newline expected'
		return
	fi

	if ! [ -n "$_heredoc" ]; then
		unset _heredoc _heredoc__input
		bres_set_2 false 'empty here''doc-constant'
		return
	fi

	bstr_prefix "$_heredoc" '\'
	if bres_check _heredoc; then
		:
	else
		bstr_prefix "$_heredoc" "'"
		if ! bres_check _heredoc; then
			unset _heredoc _heredoc__input
			bres_set_2 false 'only escaped here''docs supported'
			return
		fi
		bstr_suffix "$_heredoc" "'"
		if ! bres_check _heredoc; then
			unset _heredoc _heredoc__input
			bres_set_2 false 'only escaped here''docs supported'
			return
		fi
	fi

	bstr_match "$_heredoc" '*[!A-Za-z0-9_]*'
	if bres_check; then
		unset _heredoc _heredoc__input
		bres_set_2 false 'here''doc contstant invalid'
		return
	fi


	bstr_suffix "$_heredoc__input" "$bobshell_newline""$_heredoc"
	if bres_check; then
		bres_append ''
	else
		bstr_split_v3 "$_heredoc__input" "$bobshell_newline""$_heredoc""$bobshell_newline"
		if ! bres_check; then
			unset _heredoc _heredoc__input
			bres_set_2 false 'here''doc end marker not found'
			return
		fi
	fi
	bres_2="$bres_2$bobshell_newline"
	unset _heredoc _heredoc__input
}
