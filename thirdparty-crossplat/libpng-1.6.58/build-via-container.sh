#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../../thirdparty-linux/common-vars.sh

OS_NAME=$(uname -s)
case "${OS_NAME}" in
    Linux*)
################################################################################
docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd libpng-1.6.58/

  mkdir -p /outputs/bin

  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir (/tmp/work/...) into DWARF debug info that won't exist on hosts.
  ./configure --prefix=/outputs CFLAGS="-O2" \
              --disable-static --enable-shared \
              --disable-tests --disable-tools \
              --with-binconfigs=no
  make -j
  make install
  rm /outputs/bin/libpng-config

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-libpng
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  tar xf $SCRIPTDIR/*.tar.*
  cd libpng-1.6.58/

  mkdir -p $OUTDIR/bin
  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir into DWARF debug info that won't exist on other hosts.
  ./configure --prefix=$OUTDIR CFLAGS="-O2" \
              --disable-static --enable-shared \
              --disable-tests --disable-tools \
              --with-binconfigs=no
  make -j
  make install

  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/lib/libpng16.la
  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/lib/pkgconfig/libpng16.pc

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac
