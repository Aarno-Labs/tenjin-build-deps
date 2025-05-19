#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  git clone https://github.com/madler/unzip
  cd unzip
  git checkout 0b82c20ac7375b522215b567174f370be89a4b12

  cp unix/Makefile .
  make list

  sed -i.bak 's@usr/local@$TMPSUBDIR@' Makefile

  make generic
  make install

  ls -l $TMPSUBDIR/*

  strip --strip-debug     $TMPSUBDIR/bin/unzip
  cp $TMPSUBDIR/bin/unzip /outputs/bin/unzip
EOF
