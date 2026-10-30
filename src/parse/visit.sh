
shelduck transform replace visit shelduck_parse_visit

# script = ( unstructured | command [ heredoc ] ), script


# fun: visit_child EXE IGNORED [ ARGS ...]
visit_child() {
	_visit_child="$1"
	shift 2
	set -- "$_visit_child" "$@"
	unset _visit_child
	"$@"
}

# fun: visit_wrap_listener
visit_wrap_listener() {

}

bobshell_shift_prepend2() {

}

bobshell_skip2_exec() {
	_bobshell_skip2_exec="$1"
	shift 2
	set -- "$_bobshell_skip2_exec" "$@"
	unset _bobshell_skip2_exec
	"$@"
}

visit_script() {

	# $1 is total input
	# $2 is not yet parsed input
	set -- "$1" "$@"
	while [ -n "$2" ]; do
		bobshell_skip2_exec visit_unstructured "$@" script
		if bobshell_result_check; then
			bobshell_result_1="$1"
			shift 2
 			set -- "$bobshell_result_1" "$bobshell_result_2" "$@"
		else
			bobshell_skip2_exec visit_command "$@" script
			if bobshell_result_check; then
				bobshell_result_1="$1"
				shift 2
 				set -- "$bobshell_result_1" "$bobshell_result_2" "$@"

        		visit_optional bobshell_skip2_exec visit_heredoc "$@" script
          		visit_result_optional
          		# visit_optional visit_heredoc "$@" script
			fi
		fi
	done

	bobshell_shift_exec 1 "$@" script "$1"
	bobshell_result_set true ''
}


# fun: visit_unstructured INPUT [ LISTENER [ LISTENER ARGS ... ] ]
# listener: fun: TYPE FOUND
#           res: true stop
#                true skip
#                true rewrite newvalue
#                false error message
# res: true INPUT
# res: false
visit_unstructured() {
	if [ -z "$1" ]; then
		bobshell_result_set_2 false 'str empty'
		return
	fi

	if bobshell_starts_with "$1" 'shelduck '; then
		bobshell_result_set_2 false 'str starts with shelduck command'
		return
	fi

	bobshell_str_split_v3 "$1" "$bobshell_newline"'shelduck '
	if bobshell_result_check _visit_unstructured__before _visit_unstructured__after; then
		shift
		set -- 'shelduck '"$_visit_unstructured__after" "$@" unstructured "$_visit_unstructured__before$bobshell_newline"
		unset _visit_unstructured__before _visit_unstructured__after
		bobshell_shift_exec 1 "$@"
		# todo bobshell_result_assert _visit_unstructured__listen_result
	else
		bobshell_shift_exec 1 "$@" unstructured "$1"
	fi
	bobshell_result_set true "$1"
}

# fun: visit_optional VISIT_FUNCTION INPUT  LISTENER [ARGS ...]
# fun
visit_optional() {
	"$@"
	if bobshell_result_check _visit_optional; then
		bobshell_result_set true "$_visit_optional"
		unset _visit_optional
	else
		bobshell_result_set true "$1"
	fi
}

visit_one_or_more() {
	true
}

visit_zero_or_more() {

}


# fun: visit_script INPUT LISTENER [ LISTENER ARGS ... ]
# res: true
# listener:
#     fun: listener TYPEPATH FOUND REST
#     res: true [ stop | replace ]
visit_script() {
	#
	true

}


visit_command() {
	_visit__found=
	_visit__input="$1"
	while [ -n "$_visit__input" ]; do
		bobshell_str_split_v3 "$_visit__input" "${bobshell_newline}"
		if bobshell_result_check _visit__line _visit__input; then
			bobshell_var_append _visit__found "$_visit__line$bobshell_newline"
			bobshell_str_suffix "$_visit__line" '\'
			unset _visit__line
			if ! bobshell_result_check; then
				break
			fi
		else
			bobshell_var_append _visit__found "$_visit__input"
			_visit__input=
			break
		fi
	done
	bobshell_result_set true "$_visit__found" "$_visit__input"
	unset _visit__found _visit__input
}

visit_heredoc() {
	bobshell_die visit_heredoc: not implemented
}



# fun: visit_heredoc  INPUT
# res: true VALUE NEXT
visit_heredoc() {
	bobshell_str_lstrip "$1" ' '
	_visit_heredoc="$bobshell_result_2"

	bobshell_str_prefix "$_visit_heredoc" '<<'
	if ! bobshell_result_check _visit_heredoc; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false '"<<" expected'
		return
	fi


	bobshell_str_split_v3 "$_visit_heredoc" "$bobshell_newline"
	if ! bobshell_result_check _visit_heredoc _visit_heredoc__input; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'newline expected'
		return
	fi

	if ! [ -n "$_visit_heredoc" ]; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'empty heredoc-constant'
		return
	fi

	bobshell_str_prefix "$_visit_heredoc" '\'
	if bobshell_result_check _visit_heredoc; then
		:
	else
		bobshell_str_prefix "$_visit_heredoc" "'"
		if ! bobshell_result_check _visit_heredoc; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'only escaped heredocs supported'
			return
		fi
		bobshell_str_suffix "$_visit_heredoc" "'"
		if ! bobshell_result_check _visit_heredoc; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'only escaped heredocs supported'
			return
		fi
	fi

	bobshell_str_match "$_visit_heredoc" '*[!A-Za-z0-9_]*'
	if bobshell_result_check; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'heredoc contstant invalid'
		return
	fi


	bobshell_str_suffix "$_visit_heredoc__input" "$bobshell_newline""$_visit_heredoc"
	if bobshell_result_check; then
		bobshell_result_append ''
	else
		bobshell_str_split_v3 "$_visit_heredoc__input" "$bobshell_newline""$_visit_heredoc""$bobshell_newline"
		if ! bobshell_result_check; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'heredoc end marker not found'
			return
		fi
	fi
	bobshell_result_2="$bobshell_result_2$bobshell_newline"
	unset _visit_heredoc _visit_heredoc__input
}


x() {
visit_heredoc "<<'EOF'
heredocvalue
EOF
hello"
#	script ...
#		heredoc ...
#			special <<
#           name EOF
#           special '\n
#           value heredocvalue\n
#           name EOF
#           special


}

# fun: visit_heredoc_header INPUT
# res: true VALUE NEXT
visit_heredoc_header() {
	bobshell_str_lstrip "$1" ' '
	_visit_heredoc="$bobshell_result_2"

	bobshell_str_prefix "$_visit_heredoc" '<<'
	if ! bobshell_result_check _visit_heredoc; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false '"<<" expected'
		return
	fi


	bobshell_str_split_v3 "$_visit_heredoc" "$bobshell_newline"
	if ! bobshell_result_check _visit_heredoc _visit_heredoc__input; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'newline expected'
		return
	fi

	if ! [ -n "$_visit_heredoc" ]; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'empty heredoc-constant'
		return
	fi

	bobshell_str_prefix "$_visit_heredoc" '\'
	if bobshell_result_check _visit_heredoc; then
		:
	else
		bobshell_str_prefix "$_visit_heredoc" "'"
		if ! bobshell_result_check _visit_heredoc; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'only escaped heredocs supported'
			return
		fi
		bobshell_str_suffix "$_visit_heredoc" "'"
		if ! bobshell_result_check _visit_heredoc; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'only escaped heredocs supported'
			return
		fi
	fi

	bobshell_str_match "$_visit_heredoc" '*[!A-Za-z0-9_]*'
	if bobshell_result_check; then
		unset _visit_heredoc _visit_heredoc__input
		bobshell_result_set_2 false 'heredoc contstant invalid'
		return
	fi


	bobshell_str_suffix "$_visit_heredoc__input" "$bobshell_newline""$_visit_heredoc"
	if bobshell_result_check; then
		bobshell_result_append ''
	else
		bobshell_str_split_v3 "$_visit_heredoc__input" "$bobshell_newline""$_visit_heredoc""$bobshell_newline"
		if ! bobshell_result_check; then
			unset _visit_heredoc _visit_heredoc__input
			bobshell_result_set_2 false 'heredoc end marker not found'
			return
		fi
	fi
	bobshell_result_2="$bobshell_result_2$bobshell_newline"
	unset _visit_heredoc _visit_heredoc__input
}
