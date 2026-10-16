
shelduck_str_equals() {
	case "$1" in
		("$2") return ;;
		(*)    return 1 ;;
	esac
}
