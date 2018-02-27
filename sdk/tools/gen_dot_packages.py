#!/usr/bin/env python
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import os
import shutil
import sys

def main():
  def create_manifest_line(name, path):
    return "%s:file://%s/\n" % (name, path)

  parser = argparse.ArgumentParser(
      description="Generate .packages file for dart package")
  parser.add_argument("--out", help="Path to .packages file to generate",
                      required=True)
  parser.add_argument("--package-name", help="Name of this package",
                      required=True)
  parser.add_argument("--source-dir", help="Path to package source",
                      required=True)
  parser.add_argument("--public-dir", help="Path to Fuchsia Dart public API",
                      required=True)
  parser.add_argument("--prebuilt", 
                      help="Path to the prebuilt .packages manifest", 
                      required=True)
  args = parser.parse_args()

  manifest_file_path = args.out
  prebuilt_manifest_file_path = args.prebuilt
  package_name = args.package_name
  source_dir = args.source_dir
  public_dir = args.public_dir

  packages = []

  with open(prebuilt_manifest_file_path, "r") as prebuilt_manifest:
    for line in prebuilt_manifest:
      (name, relative_path) = line.strip().split(':', 1)
      full_path = os.path.join(public_dir, relative_path)
      packages.append(tuple([name, full_path]))

  with open(manifest_file_path, "a+") as manifest_file:
    for name, path in packages:
      manifest_file.write(create_manifest_line(name, path))
    manifest_file.write(create_manifest_line(package_name, source_dir))
  return 0

if __name__ == '__main__':
  sys.exit(main())
