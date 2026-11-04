


shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/str/quote.sh



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


shelduck_preserve1() {
	eval 'set -- "$'"$1"'" "$@"'
	set -- "$2="'"$3"' "$@"
	bobshell_shiftexec 3 "$@"
	eval "$1"
}

shelduck_preserve2() {
	eval 'set -- "$'"$1"'" "$'"$2"'" "$@"'
	set -- "$3"'="$2"; '"$4"'="$3"' "$@"
	bobshell_shiftexec 5 "$@"
	eval "$1"
}

shelduck_preserve3() {
	eval 'set -- "$'"$1"'" "$'"$2"'" "$'"$3"'" "$@"'
	set -- "$4"'="$2"; '"$5"'="$3"; '"$6"'="$4"' "$@"
	bobshell_shiftexec 7 "$@"
	eval "$1"
}
