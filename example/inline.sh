#!/bin/sh
set -eu
# example using shelduck.

# load shelduck engine from url at runtime
shelduck_src="$(curl -fsSL https://raw.githubusercontent.com/legeyda/shelduck/refs/heads/main/shelduck.sh)"
eval "$shelduck_src"

# declare dependencies
shelduck import -a die \
	https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/main/base.sh

# use dependencies
die 'shelduck works!'


