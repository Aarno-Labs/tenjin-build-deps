#!/bin/sh

set -eu

BUILDER=alpine-3.21

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eu
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd patch-*/

  LDFLAGS=-static ./configure --prefix=/outputs
  make -j4
  make install
  strip --strip-debug /outputs/bin/patch

EOF
