

# DEPRECATED
# fun: shelduck_resolve URL [ ARGS ... ]
# api: public
shelduck_resolve() {
	bobshell_log_warn 'shelduck: resolve is deprecated, use build instead'
	shelduck_build "$@"
}
