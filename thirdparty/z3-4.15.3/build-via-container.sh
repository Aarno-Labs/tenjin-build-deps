#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd z3-*/

  apt-get update && apt-get -y --no-install-recommends install

  cmake -B build -S . -G "Unix Makefiles"
  cmake --build   build -- -j$(nproc --all)
  cmake --install build --prefix /outputs

  strip --strip-debug        /outputs/bin/z3
  chown -R $(id -u):$(id -g) /outputs
EOF
