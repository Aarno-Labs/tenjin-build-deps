#!/bin/bash

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../../thirdparty-linux/common-vars.sh

OS_NAME=$(uname -s)
case "${OS_NAME}" in
    Linux*)
################################################################################
docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    bash -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd jpeg-10/

  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir (/tmp/work/...) into DWARF debug info that won't exist on hosts.
  ./configure --prefix=/outputs CFLAGS="-O2" --enable-static=no
  make -j
  make install

  # We only need the libraries, and the binaries embed the build dir in RUNPATH
  rm /outputs/bin/{cjpeg,djpeg,jpegtran,rdjpgcom,wrjpgcom}

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-libjpeg
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  tar xf $SCRIPTDIR/*.tar.*
  cd jpeg-10/

  mkdir -p $OUTDIR/
  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir into DWARF debug info that won't exist on other hosts.
  ./configure --prefix=$OUTDIR CFLAGS="-O2" --enable-static=no
  make -j
  make install

  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/lib/libjpeg.la
  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/lib/pkgconfig/libjpeg.pc

  # We only need the libraries, and the binaries embed the build dir in RUNPATH
  rm $OUTDIR/bin/{cjpeg,djpeg,jpegtran,rdjpgcom,wrjpgcom}

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac
