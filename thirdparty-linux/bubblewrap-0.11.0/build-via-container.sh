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
  cd bubblewrap-*/

  apt-get update && apt-get -y --no-install-recommends install libcap-dev

  meson            ../_builddir
  meson configure --prefix $TMPSUBDIR  ../_builddir
  meson compile -C ../_builddir
  meson test    -C ../_builddir
  meson install -C ../_builddir

  strip --strip-debug     $TMPSUBDIR/bin/bwrap
  chown $(id -u):$(id -g) $TMPSUBDIR/bin/bwrap

  cp $TMPSUBDIR/bin/bwrap /outputs/bin/
EOF
