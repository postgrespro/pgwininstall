#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""
This script reads list of glob patterns from files, specified in the
command-line and generates lists of files for each pattern
"""
from __future__ import print_function
import sys
import fnmatch
import os
import os.path

#pylint: disable=invalid-name
filelist_name = sys.argv.pop(1)
if os.path.isdir(filelist_name):
    # Generate filelist ourselves
    pwd = os.getcwd()
    os.chdir(filelist_name)
    filelist = set()
    for dirname, subdirlist, files in os.walk("."):
        dirname = dirname.replace("\\", "/")
        for f in files:
            filelist.add(dirname + "/" + f)
    os.chdir(pwd)
else:
    with open(filelist_name, "r") as f:
        filelist = set(map(lambda x: x.strip(), f.readlines()))

for module in sys.argv[1:]:
    modname = module[:module.find(".")]
    print("Processing module ", modname, file=sys.stderr)
    with open(module, "r") as f:
        patterns = [x.strip() for x in f.readlines()]
    for p  in patterns:
        if p.startswith("./bin/") and not p.endswith(".dll"):
            patterns.append("./share/locale/*/LC_MESSAGES/" +
                            p[6:p.rfind(".")] + "*.mo")
    found = set()
    for p  in patterns:
        if p.startswith("#"):
            continue
        for f in filelist:
            if fnmatch.fnmatch(f, p):
                found.add(f)
    filelist -= found
    with open(modname + "_list.nsi", "w") as out:
        curdir = ""
        for f in sorted(found):
            filedir = os.path.dirname(f)
            if filedir != curdir:
                print("SetOutPath $INSTDIR" + filedir[1:].replace("/", "\\"),
                      file=out)
                curdir = filedir
            print("File ${PG_INS_SOURCE_DIR}" + f[1:].replace("/", "\\"),
                  file=out)

# When all module files are processed:
if filelist:
    print("Following unprocessed files found:\n", ", ".join(sorted(filelist)),
          file=sys.stderr)
    sys.exit(1)
