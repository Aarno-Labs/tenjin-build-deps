#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir -p $TMPSUBDIR
  cd $TMPSUBDIR

  #zlib's 1.3.1 release does not include CMake files when installing, so
  #we build it from a more recent Git commit.

  git clone https://github.com/madler/zlib.git
  cd zlib
  git checkout --detach 5a82f71ed1dfc0bec044d9702463dbdf84ea3b71

  apt-get update && apt-get -y --no-install-recommends install

  # Make sure even libz.a is built with -fPIC
  cmake -B build -S . -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/outputs -DCMAKE_C_FLAGS="-fPIC"
  cmake --build   build -- -j$(nproc --all)
  cmake --install build

  chown -R $(id -u):$(id -g) /outputs
EOF
