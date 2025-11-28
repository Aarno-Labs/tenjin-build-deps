BUILDERNAME="${BUILDER:-debian-bullseye}"
IMAGENAME="ghcr.io/aarno-labs/tenjin-${BUILDERNAME}-builder:rev-85f982358"
TMPSUBDIR=/tmp/tenjin-build-deps/canary/183018384101018888

OUTDIR=$(realpath $SCRIPTDIR/../out)

# For context on this nonsense, see COMMENTARY(pkg-config-paths) in the Tenjin CLI source.
# The contents are designed for greppability, e.g. search for "itlaterok/prefix" or whatever.
#
FIFTY=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
RILLY=thisverylongpathistogiveusroomtooverwriteitlaterok
TWOHUNDREDFIFTY=${FIFTY}${FIFTY}${FIFTY}${FIFTY}${RILLY}
PATH_OF_UNUSUAL_SIZE=/tmp/$TWOHUNDREDFIFTY/$TWOHUNDREDFIFTY
