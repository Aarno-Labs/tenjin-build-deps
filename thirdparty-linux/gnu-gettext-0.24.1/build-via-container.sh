#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.xz
  cd gettext-*/

  ./configure --prefix=/outputs --enable-relocatable --disable-c++ --disable-static --enable-shared --disable-dependency-tracking
  make -j4
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
