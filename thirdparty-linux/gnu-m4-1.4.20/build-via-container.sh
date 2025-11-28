#!/bin/sh

set -eu

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

PROGNAME=m4

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eu
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd ${PROGNAME}-*/

  mkdir -p $(dirname $PATH_OF_UNUSUAL_SIZE)
  ln -s /outputs $PATH_OF_UNUSUAL_SIZE

  ./configure \
            --prefix=$PATH_OF_UNUSUAL_SIZE \
            --without-libintl-prefix --without-libiconv-prefix --without-libsigsegv-prefix \
            --with-packager=Tenjin --disable-rpath

  make -j4

  make install
  strip --strip-debug /outputs/bin/${PROGNAME}
  mv /outputs/bin/${PROGNAME} /outputs/bin/${PROGNAME}.uncooked
EOF
