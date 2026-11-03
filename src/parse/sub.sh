

# fun: shelduck_parse_sub FUNCTION INPUT IGNORED [ ARGS ... ]
shelduck_parse_sub() {
	_shelduck_parse_sub__1="$1"
	_shelduck_parse_sub__2="$2"
	shift 3
	set -- "$_shelduck_parse_sub__1" "$_shelduck_parse_sub__2" "$@"
	unset _shelduck_parse_sub__1 _shelduck_parse_sub__2
	"$@"
}
