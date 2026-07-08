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

  tar xf /inputs/*.tar.xz
  cd gettext-*/

  ./configure --prefix=/outputs --enable-relocatable --disable-c++ --disable-static --enable-shared --disable-dependency-tracking
  make -j4
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-pcre2
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  tar xf $SCRIPTDIR/*.tar.xz
  cd gettext-*/

  ./configure --prefix=$OUTDIR --enable-relocatable --disable-c++ --disable-static --enable-shared --disable-dependency-tracking
  make -j4
  make install

  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/bin/libtoolize
  sed -i'' -e "s|$OUTDIR|/outputs|g" $OUTDIR/lib/libltdl.la

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac

