#!/bin/sh

set -eux

BUILDER=alpine-3.21

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../common-vars.sh

PROGNAME=pkg-config

# For context on this nonsense, see COMMENTARY(pkg-config-paths) in the Tenjin CLI source.
# The contents are designed for greppability, e.g. search for "itlaterok/prefix" or whatever.
#
FIFTY=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
RILLY=thisverylongpathistogiveusroomtooverwriteitlaterok
TWOHUNDREDFIFTY=${FIFTY}${FIFTY}${FIFTY}${FIFTY}${RILLY}
PATH_OF_UNUSUAL_SIZE=/tmp/$TWOHUNDREDFIFTY/$TWOHUNDREDFIFTY

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
            --user $(id -u):$(id -g) \
                     $IMAGENAME    sh -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  tar xf /inputs/*.tar.*
  cd pkg-config-*/

  mkdir -p $PATH_OF_UNUSUAL_SIZE

  # nobody ever wanted to build pkg-config statically before???
  # libtool, you're worse than Aaron Burr.
  sed -i.bak 's/\$(AM_V_CCLD)\$(LINK) \$(pkg_config_OBJECTS) \$(pkg_config_LDADD)/gcc -static \$(pkg_config_OBJECTS) \$(top_builddir)\/glib\/glib\/.libs\/libglib-2.0.a  \$(LIBS) -o pkg-config/' Makefile.in


  ./configure --prefix=$PATH_OF_UNUSUAL_SIZE/prefix \
           --with-pc-path=$PATH_OF_UNUSUAL_SIZE/lib/pkgconfig:$PATH_OF_UNUSUAL_SIZE/share/pkgconfig \
           --with-system-include-path=$PATH_OF_UNUSUAL_SIZE/sysinc:/usr/include \
           --with-system-library-path=$PATH_OF_UNUSUAL_SIZE/syslib:/usr/lib:/lib \
           --disable-shared --with-internal-glib --disable-host-tool

  make -j4
  make install

  ls -l $PATH_OF_UNUSUAL_SIZE/prefix/*

  strip --strip-debug     $PATH_OF_UNUSUAL_SIZE/prefix/bin/$PROGNAME
  cp $PATH_OF_UNUSUAL_SIZE/prefix/bin/$PROGNAME /outputs/bin/$PROGNAME.uncooked
  mkdir -p /outputs/share/aclocal/
  cp $PATH_OF_UNUSUAL_SIZE/prefix/share/aclocal/pkg.m4 /outputs/share/aclocal/
EOF
