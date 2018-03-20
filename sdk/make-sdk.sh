#!/bin/sh

set -e

if [ -z "$FUCHSIA_DIR" -o -z "$FUCHSIA_OUT_DIR" -o -z "$FUCHSIA_BUILD_DIR" ]; then
  echo "$0 must be run from the fx tool:"
  echo "fx exec $0"
  exit 1
fi

readonly SCRIPT_LOCATION="$(cd $(dirname ${BASH_SOURCE[0]} ) && pwd)"
readonly OUT_DIR="$(dirname ${SCRIPT_LOCATION})/out/sdk"

##### Create a clean slate
rm -rf ${OUT_DIR}
mkdir -p ${OUT_DIR}

echo "Building proto-SDK into: ${OUT_DIR}"

# copy flutter
rsync --exclude .git/jiri --exclude bin/cache/ -a "${FUCHSIA_DIR}/third_party/dart-pkg/git/flutter/" "${OUT_DIR}/flutter/"
rsync --exclude .git/jiri -a "${FUCHSIA_BUILD_DIR}/dart_host_x64/dart-sdk/" "${OUT_DIR}/dart-sdk/"
rsync -a "${FUCHSIA_BUILD_DIR}/dartlang/gen/dart-pkg/sky_engine" "${OUT_DIR}/sky_engine"
