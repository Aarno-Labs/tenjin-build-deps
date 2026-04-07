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
  cd pcre2-*/

  cmake -B build -S . -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/outputs -DBUILD_SHARED_LIBS=ON -DPCRE2_STATIC_PIC=ON
  cmake --build   build --target install --parallel

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

  tar xf $SCRIPTDIR/*.tar.*
  cd pcre2-*/

  cmake -B build -S . -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$OUTDIR -DBUILD_SHARED_LIBS=ON -DPCRE2_STATIC_PIC=ON
  cmake --build   build --target install --parallel

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac

