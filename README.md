

Shelduck is a dependency resolver for POSIX-Shell scripts.




## Usage

Add the following command to script. 

	shelduck import https://example.com/script.sh

Script will be added either in at [compile time](#resolve-at-compile-time) or [at runtime](#resolve-at-runtime).


For a real example, import and use a function from [bobshell](https://github.com/legeyda/bobshell/tree/unstable):

	shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh
	bobshell_contains hello ell && echo yes || echo no

Imported function can be aliased for readability.

	shelduck import --alias contains https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh
	contains hello ell && echo yes || echo no



### Resolve at compile time

[Install](#installation) shelduck.



Compile script:

	shelduck resolve file://script-src.sh > script-dest.sh

All "shelduck import" commands from `script-src.sh` will be recursively resolved.




### Resolve at runtime

#### Using shelduck run

[Install](#installation) shelduck.

Suppose `script.sh` contains "shelduck import" commands.

Run:

	shelduck run script.sh

Or add shebang to script.

	#!/usr/bin/env shelduck_run

Then make script executable and run.

	chmod +x script.sh
	./script.sh



#### Load library manually

Load shelduck library.

Option 1. Without installing anything.

	shelduck_lib_src=$(curl -fsSL https://github.com/legeyda/shelduck/releases/latest/download/shelduck.sh)
	eval "$shelduck_lib_src"

Option 2. If shelduck is already [installed](#installation), source it.

	. "$HOME/.local/share/shelduck/shelduck.sh"

Now every "shelduck import" command will be resolved at runtime.


## Installation

Option 1:

	curl -fsSL https://github.com/legeyda/shelduck/releases/latest/download/install.sh | sh

Option 2:

	git clone git@github.com:legeyda/shelduck.git
	cd shelduck
	sh ./run install




## Libraries of reusable code

There is no special requirements for script to be supported by shelduck. Any script available via url will do.

The only recommendation is to prefix all functions with unique prefix to avoid collisions.

For example of a library of reusable code see https://github.com/legeyda/bobshell/tree/unstable.


## Making a release

	git tag --annotated v0.1.0-alphaN
	git push --tags
	
	docker login
	./run docker_push