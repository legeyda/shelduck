# Shelduck
[![Ask DeepWiki](https://devin.ai/assets/askdeepwiki.png)](https://deepwiki.com/legeyda/shelduck)

Shelduck is a dependency resolver for POSIX-compliant shell scripts. It allows you to import remote or local scripts into your project, either at runtime or during a compile-time bundling step.

## Installation

You can install `shelduck` using `curl`:
```sh
curl -fsSL https://github.com/legeyda/shelduck/releases/latest/download/install.sh | sh
```
This will install the `shelduck` and `shelduck_run` executables to `$HOME/.local/bin`. Ensure this directory is in your `PATH`.

Alternatively, developers can clone the repository and run the installation script:
```sh
git clone https://github.com/legeyda/shelduck.git
cd shelduck
./run install
```

## Usage

The core of Shelduck is the `import` command. You add it to your script to declare a dependency.

```sh
# In your script.sh

# Import functions from another script
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# Now you can use functions from the imported script, like bobshell_contains
bobshell_contains "hello world" "world" && echo "✅ It contains world"
```

You can also create an alias for imported functions for better readability. Shelduck matches the alias against the end of a function name. For example, to create an alias `contains` for the function `bobshell_contains`:

```sh
# This creates an alias "contains" for a function ending in "contains"
shelduck import --alias contains https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# Use the aliased function
contains "hello world" "world" && echo "✅ It contains world"
```

For more explicit aliasing, use the `new_name=old_function_suffix` syntax:
```sh
# Explicitly alias bobshell_contains to check_substring
shelduck import --alias check_substring=bobshell_contains https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/string.sh

# Use the new, explicit alias
check_substring "hello world" "world" && echo "Substring found!"
```

Once you have added `import` commands, you can execute your script in two ways: resolving dependencies at runtime or at compile time.

### Resolve at Runtime

This approach resolves dependencies on-the-fly each time the script is executed. This is useful during development.

#### Option 1: Using `shelduck_run`

After [installing](#installation), you can use the `shelduck_run` command or shebang.

To run your script with the command:
```sh
shelduck_run ./your_script.sh
```

Or, add the `shelduck_run` shebang to the top of your script:
```sh
#!/usr/bin/env shelduck_run
set -eu

shelduck import ...
```
Make the script executable and run it directly:
```sh
chmod +x ./your_script.sh
./your_script.sh
```

#### Option 2: Sourcing the Library Manually

You can source the `shelduck` library at the beginning of your script. This is useful for environments where you cannot install `shelduck` globally.

Fetch and evaluate the library directly from the web:
```sh
#!/bin/sh
set -eu

# Load shelduck from URL at runtime
shelduck_lib_src=$(curl -fsSL https://github.com/legeyda/shelduck/releases/latest/download/shelduck.sh)
eval "$shelduck_lib_src"

# Now, 'shelduck import' commands will work
shelduck import https://raw.githubusercontent.com/legeyda/bobshell/refs/heads/unstable/base.sh
die "This works!"
```

### Resolve at Compile Time

This approach bundles all your script's dependencies into a single, self-contained file. This is ideal for distributing your script to users who don't have `shelduck` installed.

Use the `shelduck resolve` command:
```sh
shelduck resolve ./your_script_with_imports.sh > ./bundled_script.sh
```
The resulting `bundled_script.sh` will contain all the code from its dependencies and can be run with any standard POSIX shell (`sh ./bundled_script.sh`).

## Creating Reusable Libraries

Any shell script accessible via a URL (`https://`, `http://`) or a local file path (`file://`) can be imported by Shelduck. There are no special requirements for a script to be a library.

To avoid function name collisions, it is highly recommended to prefix all public functions in your library with a unique namespace. For a well-structured example, see the [bobshell](https://github.com/legeyda/bobshell/tree/unstable) repository.

## Docker Usage

A Docker image is available to run `shelduck` in an isolated environment.

### Build the Image
```sh
docker build -t legeyda/shelduck .
```
The `run` script provides a helper for this: `./run docker_build`.

### Run `shelduck` Commands
You can use the Docker image to run `shelduck` commands, such as `resolve`. Mount your project directory into the container.

```sh
docker run --rm -v "$(pwd)":/work -w /work legeyda/shelduck resolve your_script.sh > bundled_script.sh
```

## Development

The `./run` script is the main entry point for development tasks.

*   **Build & Test:** Build the project and run the test suite.
    ```sh
    ./run ci_build
    ```

*   **Clean:** Remove build artifacts from the `target/` directory.
    ```sh
    ./run clean
    ```
*   **Release:** The release process is automated via GitHub Actions. To create a new release:
    1.  Create an annotated git tag (e.g., `git tag -a v0.1.0 -m "Release v0.1.0"`).
    2.  Push the tag to the repository (`git push --tags`).
    
    The CI workflow will build the release assets (`shelduck.sh`, `install.sh`) and publish them to a new GitHub Release.