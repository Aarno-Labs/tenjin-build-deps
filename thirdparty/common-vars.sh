BUILDERNAME="${BUILDER:-debian-bullseye}"
IMAGENAME="ghcr.io/Aarno-Labs/tenjin-${BUILDERNAME}-builder:rev-85f982358"
TMPSUBDIR=/tmp/183018384101018888

OUTDIR=$(realpath $SCRIPTDIR/../out)
