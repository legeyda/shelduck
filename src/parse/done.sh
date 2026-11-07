
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/set.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/check.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/result/unset.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/misc/shiftexec.sh



# fun: shelduck_parse_done ORIGINPUT [ LISTENER ... ] [ TYPE ... ] FOUND INPUT
shelduck_parse_done() {
	if [ $# -le 3 ]; then
		shift
		bobshell_result_set true "$@"
		return
	fi

	bobshell_result_set_2 true noop
	bobshell_shiftexec 1 "$@"
	if bobshell_result_check; then
		case "$bobshell_result_2" in
			(noop)
				while [ $# -gt 2 ]; do
					shift
				done
				bobshell_result_set_3 true "$@"
				;;
			(cancel) #
				bobshell_result_set_2 false 'cancelled by listener'
				;;
			(rewrite)
				bobshell_result_set_3 true "$bobshell_result_3" "$bobshell_result_4"
				;;
			(*)
				bobshell_die unsupported listener command "$bobshell_result_2"
				;;
		esac
	fi
}
