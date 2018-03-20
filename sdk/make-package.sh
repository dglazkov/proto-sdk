#!/bin/sh

# TODO: Not needing to point at Fuchsia checkout root is the goal
#       of this exercise.
if [ -z "${FUCHSIA_DIR}" ]; then
    echo "Need to set FUCHSIA_DIR, pointing at Fuchsia checkout root"
    exit 1
fi

if [ -z "${SOURCE_DIR}" ]; then
    echo "Need to set SOURCE_DIR, the directory where the source files are."
    exit 1
fi

if [ -z "${PACKAGE_NAME}" ]; then
    echo "Need to set PACKAGE_NAME, the name of the package you'd like to fly."
    exit 1
fi

readonly SCRIPT_LOCATION="$(cd $(dirname ${BASH_SOURCE[0]} ) && pwd)"

##### These are the previous (before I started the process of moving out) values
##### of the directories.
#OUT_DIR="${FUCHSIA_DIR}/out/debug-x86-64"
#GEN_DIR="${OUT_DIR}/dartlang/gen/topaz/examples/ui/hello_material"
#PACKAGE_OUT_DIR="${OUT_DIR}/package/${PACKAGE_NAME}"
#WORKING_DIR="${OUT_DIR}/gen/topaz/examples/ui/hello_material/build"

##### These are the new locations I created.
SDK_DIR="${SCRIPT_LOCATION}/../out/sdk"
TOOLS_DIR="${SCRIPT_LOCATION}/tools"
BIN_DIR="${SCRIPT_LOCATION}/bin"
DATA_DIR="${SCRIPT_LOCATION}/data"

##### These are the moved-out new locations for scripts and bins
OUT_DIR="${SCRIPT_LOCATION}/../out"
PACKAGE_OUT_DIR="${OUT_DIR}/package/${PACKAGE_NAME}"
GEN_DIR="${OUT_DIR}/gen"
WORKING_DIR="${GEN_DIR}"

##### Create a clean slate
rm -rf ${PACKAGE_OUT_DIR}
mkdir -p ${PACKAGE_OUT_DIR}
rm -rf ${GEN_DIR}
mkdir -p ${GEN_DIR}

##### From here on, this is the sequence is gleaned from from studying 
##### `fx build -v` of hello_material_source.

# this tool computes transitive dependencies out of the prepared args.root_gen_dir:
# * turns gn paths specified in args.deps to real paths to .package files in args.root_gen_dir
# * for each .packages file, parses it and writes all of the items back out into a file
echo Computing Transitive Dependencies...
${TOOLS_DIR}/gen_dot_packages.py \
  --out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --source-dir ${SOURCE_DIR} \
  --public-dir ${SDK_DIR} \
  --package-name ${PACKAGE_NAME} \
  --prebuilt ${DATA_DIR}/dart_library.packages

# TODO: run analyzer?

# action "resources"
# the fuchsia_asset_builder collects and copies all assets into ${WORKING_DIR}
pushd ${SOURCE_DIR} > /dev/null

echo Collecting assets...
${SDK_DIR}/dart-sdk/bin/dart \
  ${SDK_DIR}/dart-pkg/git/flutter/packages/flutter_tools/bin/fuchsia_asset_builder.dart \
  --working-dir ${WORKING_DIR} \
  --packages ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --asset-manifest-out ${WORKING_DIR}/${PACKAGE_NAME}_pkgassets

popd > /dev/null

# action "sources"
# This is where the magic happens: determines the source files that
# are needed to run.
echo Finding all sources that are needed to run...
${TOOLS_DIR}/gen_dot_packages_resources.py \
  --gen-snapshot ${BIN_DIR}/gen_snapshot \
  --package ${PACKAGE_NAME} \
  --main-dart ${SOURCE_DIR}/main.dart \
  --dot-packages ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --dot-packages-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest.packages \
  --manifest-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest \
  --contents-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.contents \
  --url-mapping=dart:zircon,${SDK_DIR}/public/dart-pkg/zircon/lib/zircon.dart \
  --url-mapping=dart:fuchsia,${SDK_DIR}/public/dart-pkg/fuchsia/lib/fuchsia.dart \
  --url-mapping=dart:mozart.internal,${SDK_DIR}/lib/ui/flutter/sdk_ext/mozart.dart \
  --url-mapping=dart:ui,${SDK_DIR}/sky_engine/lib/ui/ui.dart

# action "manifest_target_name"
echo Writing package.json...
${TOOLS_DIR}/write_package_json.py \
  --name ${PACKAGE_NAME} \
  --version 0 \
  ${PACKAGE_OUT_DIR}/package.json

# action "manifest_target_name" in package.gni
echo Writing manifest...
${TOOLS_DIR}/write_manifest.py \
  --manifest ${PACKAGE_OUT_DIR}/archive_manifest \
  --manifest ${PACKAGE_OUT_DIR}/system_manifest \
  --manifest ${PACKAGE_OUT_DIR}/partial_package_manifest \
  meta/runtime=${DATA_DIR}/source_runtime \
  meta/package.json=${PACKAGE_OUT_DIR}/package.json

# action "extra_target_name" in package.gni
echo Combining manifests...
${TOOLS_DIR}/combine_manifests.py \
  ${PACKAGE_OUT_DIR}/package_manifest \
  ${PACKAGE_OUT_DIR}/partial_package_manifest \
  ${WORKING_DIR}/${PACKAGE_NAME}_pkgassets \
  ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest

# Creates meta.far etc.
echo Creating the package...
${BIN_DIR}/pm \
  -k ${DATA_DIR}/development.key \
  -o ${PACKAGE_OUT_DIR} \
  -m ${PACKAGE_OUT_DIR}/package_manifest \
  build