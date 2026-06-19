#!/bin/sh

set -eux

SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../../thirdparty-linux/common-vars.sh

CRISP_REPO=https://github.com/Aarno-Labs/Tractor-Crisp
CRISP_COMMIT=010470a663628bce89d22c6f80db5a4ff9b86c18

OS_NAME=$(uname -s)
case "${OS_NAME}" in
    Linux*)
################################################################################
SCRIPTDIR=$(dirname $(realpath "$0"))
source $SCRIPTDIR/../../thirdparty-linux/common-vars.sh

docker run --rm -i -v $SCRIPTDIR:/inputs -v $OUTDIR:/outputs \
            --network=host \
                     $IMAGENAME    bash -s <<EOF
  set -eux
  mkdir /tmp/work
  cd /tmp/work

  git clone $CRISP_REPO 
  cd Tractor-Crisp
  git switch --detach $CRISP_COMMIT

  cd tools
  cargo build --release -p find_unsafe2

  cd find_unsafe2/cargo_subcommands
  cargo build --release
  cd ../..  # -> tools

  mkdir -p /outputs/bin
  ls -l ./target/release/
  cp ./target/release/{cargo-find-,cargo-check-,find_,check_}unsafe2 /outputs/bin

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-boost
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  git clone $CRISP_REPO 
  cd Tractor-Crisp
  git switch --detach $CRISP_COMMIT

  cd tools
  cargo build --release -p find_unsafe2

  cd find_unsafe2/cargo_subcommands
  cargo build --release
  cd ../.. # -> /REPO/tools

  mkdir -p $OUTDIR/bin/
  cp ./target/release/{cargo-find-,cargo-check-,find_,check_}unsafe2 $OUTDIR/bin
  cd ..  # -> /REPO

  cd ..  # -> /
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac

