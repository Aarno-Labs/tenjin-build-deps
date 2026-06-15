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
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd libevent-*/

  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir (/tmp/work/...) into DWARF debug info that won't exist on hosts.
  ./configure --disable-openssl --prefix=/outputs CFLAGS="-O2"
  make -j
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-libevent
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  tar xf $SCRIPTDIR/*.tar.*
  cd libevent-*/

  mkdir -p $OUTDIR/
  # Override autoconf's default CFLAGS of "-g -O2": the -g bakes the absolute
  # build dir into DWARF debug info that won't exist on other hosts.
  ./configure --disable-openssl --prefix=$OUTDIR CFLAGS="-O2"
  make -j
  make install

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac
