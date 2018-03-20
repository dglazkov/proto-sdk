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
rsync --exclude .git/jiri --exclude bin/cache/ -a "${FUCHSIA_DIR}/third_party/dart-pkg" "${OUT_DIR}"
rsync -a "${FUCHSIA_BUILD_DIR}/dartlang/gen/dart-pkg/sky_engine" "${OUT_DIR}"
rsync -a "${FUCHSIA_DIR}/third_party/dart/tools/sdks/mac/dart-sdk" "${OUT_DIR}"
rsync -a "${FUCHSIA_DIR}/topaz/public" "${OUT_DIR}"
