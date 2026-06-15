#!/bin/sh

set -eu

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eu
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd make-*/

  # Give an alternate name to /outputs that is easier to spot
  # in the binary, in case it leaks through.
  mkdir -p $(dirname $TMPSUBDIR)
  ln -s /outputs $TMPSUBDIR

  ./configure --prefix=$TMPSUBDIR

  # Disallow $TMPSUBDIR from leaking into the final binary.
  sed -i.bak 's#-DLOCALEDIR=#-DLOCALEDIR_NOPE=#' Makefile
  sed -i.bak 's#LOCALEDIR#NULL#' src/main.c

  make -j4
  make install
  strip --strip-debug /outputs/bin/make

  # Tenjin doesn't seem to need localization. Save some space.
  rm -rf /outputs/share/locale
EOF
