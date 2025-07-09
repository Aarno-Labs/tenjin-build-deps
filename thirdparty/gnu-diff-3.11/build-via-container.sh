#!/bin/sh

set -eu

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eu
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd diffutils-*/

  mkdir -p $(dirname $TMPSUBDIR)
  ln -s /outputs $TMPSUBDIR

  ./configure --prefix=$TMPSUBDIR

  make -j4

  # The binary embeds a hardcoded absolute path to a locale
  # directory. Rather than point it to a fake path, break
  # encapsulation to use the system's default directory.
  sed -i.bak "s#$TMPSUBDIR#/usr#" src/paths.h
  make -j4

  make install
  strip --strip-debug /outputs/bin/diff
  rm /outputs/bin/diff3
  rm /outputs/bin/sdiff

EOF
