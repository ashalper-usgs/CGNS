#! /bin/sh
#
# Adapted from Fastmech-BMI/bin/build-gcc-solver.sh
#

GENERATOR="Unix Makefiles"
SGEN="gcc"

export GENERATOR SGEN

./build-cgnslib.sh

./create-paths-pri-solver.sh > paths.pri
./create-dirExt-prop-solver.sh > dirExt.prop
