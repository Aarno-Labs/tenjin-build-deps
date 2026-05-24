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

  tar xf /inputs/*.tar.*
  cd talloc-*/

  ./configure --prefix=/outputs --disable-python --disable-rpath-install
  make -j\$(nproc --all)
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
