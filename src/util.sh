
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
