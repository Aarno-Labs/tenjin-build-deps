#!/bin/sh

set -eux

BUILDER=alpine-3.21

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

PROGNAME=xz

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd xz-*/

  # nobody ever wanted to build xz statically before???
  # libtool, you're worse than Aaron Burr.
  sed -i.bak 's/\$(AM_V_CCLD)\$(LINK) \$(xz_OBJECTS) \$(xz_LDADD)/gcc -static \$(xz_OBJECTS) \$(top_builddir)\/src\/liblzma\/.libs\/liblzma.a \$(LIBS) -o xz/' src/xz/Makefile.in

  ./configure --prefix=$TMPSUBDIR --disable-shared --disable-scripts \
              --disable-lzmadec --disable-lzmainfo --disable-xzdec --disable-rpath

  make -j4
  make install

  ls -l $TMPSUBDIR/*

  strip --strip-debug     $TMPSUBDIR/bin/$PROGNAME
  cp $TMPSUBDIR/bin/$PROGNAME /outputs/bin/$PROGNAME
EOF
