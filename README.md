# proto-sdk

## Layout

* `sdk` is the actual proto-SDK
  * `bin` -- binaries
  * `data` -- prebuilt data bits
  * `tools` -- scripts, copied from Fuchsia source.
* `out` is created as a result of running `sdk/fly.sh`*

## Setting up

* Clone the repo `git clone https://github.com/dglazkov/proto-sdk.git`
* Run `PACKAGE_NAME="package_name" FUCHSIA_DIR="/path/to/fuchsia/root/" SOURCE_DIR="/path/to/mod/source" sdk/make-package.sh`.
* It should run and complete silently.
* The resulting package will be in `./out` directory.

## TODO

* Remove dependency on the `FUCHSIA_ROOT`.
* Create a script to reliably update stuff in `bin` and `data` from a Fuchsia 
  build output.
* Probably not use the shell script to power the whole thing?

