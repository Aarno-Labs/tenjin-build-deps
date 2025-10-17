#!/bin/sh

set -eux

BUILDER=alpine-3.21

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

PROGNAME=bzip2

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd bzip2-*/

  make -j4 LDFLAGS=-static
  make install PREFIX=$TMPSUBDIR

  ls -l $TMPSUBDIR/*

  strip --strip-debug     $TMPSUBDIR/bin/$PROGNAME
  cp $TMPSUBDIR/bin/$PROGNAME /outputs/bin/
EOF
