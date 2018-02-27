#!/bin/sh

SCRIPT_LOCATION=`pwd`
FUCHSIA_DIR="${SCRIPT_LOCATION}/.."
OUT_DIR="${FUCHSIA_DIR}/out/debug-x86-64"
PACKAGE_NAME="hello_material_source"
SOURCE_DIR="${FUCHSIA_DIR}/topaz/examples/ui/hello_material"
#GEN_DIR="${OUT_DIR}/dartlang/gen/topaz/examples/ui/hello_material"
#PACKAGE_OUT_DIR="${OUT_DIR}/package/${PACKAGE_NAME}"
#WORKING_DIR="${OUT_DIR}/gen/topaz/examples/ui/hello_material/build"

# will need anyway
FLUTTER_ROOT="${FUCHSIA_DIR}/third_party/dart-pkg/git/flutter"
FUCHSIA_ASSET_BUILDER="${OUT_DIR}/host_x64/dart-tools/fuchsia_asset_builder"

# moved out
PACKAGE_OUT_DIR="${OUT_DIR}/fly"
GEN_DIR="${OUT_DIR}/fly"
WORKING_DIR="${OUT_DIR}/fly"

# new world
SDK_DIR="${FUCHSIA_DIR}/sdk"
TOOLS_DIR="${SDK_DIR}/tools"
BIN_DIR="${SDK_DIR}/bin"

rm -rf ${PACKAGE_OUT_DIR}
mkdir -p ${PACKAGE_OUT_DIR}

# this tool computes transitive dependencies out of the prepared args.root_gen_dir:
# * turns gn paths specified in args.deps to real paths to .package files in args.root_gen_dir
# * for each .packages file, parses it and writes all of the items back out into a file 
${TOOLS_DIR}/gen_dot_packages.py \
  --out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --source-dir ${SOURCE_DIR} \
  --package-name ${PACKAGE_NAME} \
  --prebuilt ${SDK_DIR}/data/dart_library.packages

# TODO: action analyzer

# action "resources"
# pass-through: calls args.flutter_tools with the args supplied.
# the fuchsia_asset_builder collects and copies all assets into args.working_dir
${TOOLS_DIR}/asset_package.py \
  --flutter-root ${FLUTTER_ROOT} \
  --flutter-tools ${FUCHSIA_ASSET_BUILDER} \
  --working-dir ${WORKING_DIR} \
  --app-dir ${SOURCE_DIR} \
  --packages ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --asset-manifest-out ${WORKING_DIR}/${PACKAGE_NAME}_pkgassets \

# action "sources"
# This is where the magic happens: determines the source files that
# are needed to run.
${TOOLS_DIR}/gen_dot_packages_resources.py \
  --gen-snapshot ${BIN_DIR}/gen_snapshot \
  --package ${PACKAGE_NAME} \
  --main-dart ${SOURCE_DIR}/main.dart \
  --dot-packages ${GEN_DIR}/${PACKAGE_NAME}_dart_library.packages \
  --dot-packages-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest.packages \
  --manifest-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest \
  --contents-out ${GEN_DIR}/${PACKAGE_NAME}_dart_library.contents \
  --url-mapping=dart:zircon,${FUCHSIA_DIR}/topaz/public/dart-pkg/zircon/lib/zircon.dart \
  --url-mapping=dart:fuchsia,${FUCHSIA_DIR}/topaz/public/dart-pkg/fuchsia/lib/fuchsia.dart \
  --url-mapping=dart:mozart.internal,${FUCHSIA_DIR}/topaz/public/lib/ui/flutter/sdk_ext/mozart.dart \
  --url-mapping=dart:ui,${FUCHSIA_DIR}/third_party/flutter/lib/ui/ui.dart

# action "manifest_target_name"
${TOOLS_DIR}/write_package_json.py \
  --name ${PACKAGE_NAME} \
  --version 0 \
  ${PACKAGE_OUT_DIR}/package.json

# action "manifest_target_name" in package.gni
${TOOLS_DIR}/write_manifest.py \
  --manifest ${PACKAGE_OUT_DIR}/archive_manifest \
  --manifest ${PACKAGE_OUT_DIR}/system_manifest \
  --manifest ${PACKAGE_OUT_DIR}/partial_package_manifest \
  meta/runtime=${FUCHSIA_DIR}/topaz/runtime/flutter_runner/meta/source_runtime \
  meta/package.json=${PACKAGE_OUT_DIR}/package.json

# action "extra_target_name" in package.gni
${TOOLS_DIR}/combine_manifests.py \
  ${PACKAGE_OUT_DIR}/package_manifest \
  ${PACKAGE_OUT_DIR}/partial_package_manifest \
  ${WORKING_DIR}/${PACKAGE_NAME}_pkgassets \
  ${GEN_DIR}/${PACKAGE_NAME}_dart_library.manifest

# Creates meta.far etc.
${BIN_DIR}/pm \
  -k ${FUCHSIA_DIR}/build/development.key \
  -o ${PACKAGE_OUT_DIR} \
  -m ${PACKAGE_OUT_DIR}/package_manifest \
  build