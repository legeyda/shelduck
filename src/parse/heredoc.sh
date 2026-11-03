


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

shelduck import ./done.sh
shelduck import ../util.sh

# fun: heredoc INPUT [LISTENER ... ]
# res: true VALUE NEXT
heredoc() {
	if [ $# -lt 2 ]; then
		set -- "$@" :
	fi

	bstr_lstrip "$1" ' '
	_heredoc__header="$bres_1"
	_heredoc__input="$bres_2"

	bstr_prefix "$_heredoc__input" '<<'
	if ! bres_check _heredoc__input; then
		unset _heredoc__header _heredoc__input
		bres_set_2 false '"<<" expected'
		return
	fi
	_heredoc__header="$_heredoc__header"'<<'

	bstr_split_v3 "$_heredoc__input" "$bobshell_newline"
	if ! bres_check _heredoc__marker _heredoc__input; then
		unset _heredoc__header _heredoc__input
		bres_set_2 false 'newline expected'
		return
	fi

	if ! [ -n "$_heredoc__marker" ]; then
		unset _heredoc__header _heredoc__marker _heredoc__input
		bres_set_2 false 'empty here''doc-constant'
		return
	fi

	_heredoc__header="$_heredoc__header""$_heredoc__marker"
	bstr_prefix "$_heredoc__marker" '\'
	if bres_check _heredoc__marker; then
		:
	else
		bstr_prefix "$_heredoc__marker" "'"
		if ! bres_check _heredoc__marker; then
			unset _heredoc__header _heredoc__marker _heredoc__input
			bres_set_2 false 'only escaped here''docs supported'
			return
		fi
		bstr_suffix "$_heredoc__marker" "'"
		if ! bres_check _heredoc__marker; then
			unset _heredoc__header _heredoc__marker _heredoc__input
			bres_set_2 false 'only escaped here''docs supported'
			return
		fi
	fi

	bstr_match "$_heredoc__marker" '*[!A-Za-z0-9_]*'
	if bres_check; then
		unset _heredoc__header _heredoc__marker _heredoc__input
		bres_set_2 false 'here''doc contstant invalid'
		return
	fi


	bstr_suffix "$_heredoc__input" "$bobshell_newline""$_heredoc__marker"
	if bres_check; then
		bres_append ''
		_heredoc__footer=$_heredoc__marker
	else
		bstr_split_v3 "$_heredoc__input" "$bobshell_newline""$_heredoc__marker""$bobshell_newline"
		if ! bres_check; then
			unset _heredoc__header _heredoc__marker _heredoc__input
			bres_set_2 false 'here''doc end marker not found'
			return
		fi
		_heredoc__footer="$_heredoc__marker$bobshell_newline"
	fi
	bres_2="$bres_2$bobshell_newline"
	_heredoc__input="$bres_3"
	unset _heredoc__marker

	shelduck_preserve3 _heredoc__header _heredoc__footer _heredoc__input \
			shelduck_parse_done "$@" here''doc content "$bres_2" "$_heredoc__footer$_heredoc__input"

	if ! bres_check; then
		unset _heredoc__header _heredoc__marker _heredoc__input
		return
	fi

	set -- "$@" here''doc "$_heredoc__header
$bres_2$_heredoc__footer" "$_heredoc__input"
	unset _heredoc__header _heredoc__marker _heredoc__input
	shelduck_parse_done "$@"
}
