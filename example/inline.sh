#!/bin/sh
set -eu

if ! command -v shelduck; then
	shelduck_src=$(curl https://github.com/legeyda/shelduck/shelduck.sh)
	eval "$shelduck_src"
fi

