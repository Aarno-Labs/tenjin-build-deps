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
  cd gmp-*/

  mkdir -p /outputs/gmp-6.3.0
  ./configure --enable-fat --prefix=/outputs/gmp-6.3.0
  make -j
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-ninja
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR 

  tar xf $SCRIPTDIR/*.tar.*
  cd gmp-*/

  mkdir -p $OUTDIR/gmp-6.3.0
  ./configure --enable-fat --prefix=$OUTDIR/gmp-6.3.0
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

