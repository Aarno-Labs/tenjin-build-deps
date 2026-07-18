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
  cd gperf-*/

  ./configure --prefix=/outputs
  make -j4
  make install

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-gperf
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  tar xf $SCRIPTDIR/*.tar.*
  cd gperf-*/

  ./configure --prefix=$OUTDIR
  make -j4
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

