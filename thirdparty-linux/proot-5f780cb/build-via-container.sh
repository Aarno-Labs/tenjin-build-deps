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

  git clone https://github.com/proot-me/proot
  cd proot
  git checkout --detach 5f780cba57ce7ce557a389e1572e0d30026fcbca

  apt-get update && apt-get -y --no-install-recommends install libtalloc-dev

  make -C src/

  strip --strip-debug src/proot
  chown $(id -u):$(id -g) src/proot
  mkdir -p /outputs/bin
  cp src/proot /outputs/bin/proot
EOF
