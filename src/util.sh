
shelduck_str_equals() {
	case "$1" in
		("$2") return ;;
		(*)    return 1 ;;
	esac
}

# fun: shelduck_shift_exec SHIFTNUM IGNORED ... COMMAND [ARGS...]
shelduck_shift_exec() {
	shift "$1"
	shift
	"$@"
}

# fun: shelduck_split_args [ARGS ... ]
# res: ARG1 ARG2
shelduck_split_args() {
	eval 'bobshell_str_quote '"$1" # todo fix injection
	bobshell_result_set true "$bobshell_result_1"
}
