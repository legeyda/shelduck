

# shelduck_src
# env: PREFIX?
#      DESTDIR
install_shelduck() {
	SHELDUCK_INSTALL_NAME=shelduck
	bobshell_scope_mirror SHELDUCK_INSTALL_ BOBSHELL_INSTALL_
	bobshell_install_init
	bobshell_scope_mirror BOBSHELL_INSTALL_ SHELDUCK_INSTALL_



	
	# install
	bobshell_install_put_data var:shelduck_src shelduck.sh


	: "${SHELDUCK_LIBRARY_PATH:=$SHELDUCK_INSTALL_DATADIR/$SHELDUCK_INSTALL_NAME/shelduck.sh}"
	bobshell_install_put_executable stdin: "$SHELDUCK_INSTALL_NAME" <<eof
#!/bin/sh
set -eu
if [ import = "\${1:-}" ]; then
	shift
	printf 'import subcommand not available when run from installed script %s\n' "\$0"
	printf "Instead source library:\n"
	printf '. "%s"\n' '$SHELDUCK_LIBRARY_PATH'
	printf 'shelduck import'
	printf ' %s' "\$@"
	exit 1
fi
. '$SHELDUCK_LIBRARY_PATH'
shelduck "\$@"
eof

	bobshell_install_put_executable stdin: "${SHELDUCK_INSTALL_NAME}_run" <<eof
#!/bin/sh
set -eu
. '$SHELDUCK_LIBRARY_PATH'
shelduck_run "\$@"
eof

	#
	if command_available shelduck; then
		log 'shelduck was successfully installed to %s, which seems to be already in the PATH' "$SHELDUCK_INSTALL_BINDIR"
		return
	fi

	log "adding $SHELDUCK_INSTALL_BINDIR to path"

	printf '\nPATH="%s:$PATH"' "$SHELDUCK_INSTALL_BINDIR" >> "$SHELDUCK_INSTALL_DESTDIR$BOBSHELL_INSTALL_PROFILE"

}


shelduck import -a die   -a command_available   -a log   \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh
shelduck import -a fetch_url   \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/url.sh
shelduck import \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/install.sh
shelduck import \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/scope.sh



install_shelduck "$@"