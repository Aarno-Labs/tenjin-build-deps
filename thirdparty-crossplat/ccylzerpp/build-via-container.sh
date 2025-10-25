#!/bin/sh

set -eux

# The final `cc2json` binary dynamically links to (this specific version of) libLLVM,
# so this LLVM version is part of our (conceptually) exported interface.
LLVM_MAJOR_VERSION="18"
LLVM_PARTIAL_VERSION="${LLVM_MAJOR_VERSION}.1"
LLVM_FULL_VERSION="${LLVM_PARTIAL_VERSION}.8"
# Note if you change the version, you'll also need to change the release rev URL below.

# Ugh, this is FUBAR. The two root issues are that (1) we want slightly different code to run
# on Linux vs Mac, and (2) we want the build commands to happen in a Docker container on Linux
# but not on Mac. The former isn't so bad, except that the main differences are for defining
# different variables, and it's just super painful to arrange for variable expansion to happen
# at just the right times, not too early not too late, in this nested shell hell.
#
# So we separate out a few common commands and duplicate some of the rest.
#
# Oh, another note: unlike most of the other pieces of software we build,
# we don't pin the built commit of cclyzer++, we just take whatever's on HEAD
# on the `tenjin` branch. But we do at least record what we built in the final artifact.
# The motivation for this is that it eliminates an extra step in the process,
# making it easier to build new commits while making it harder to (re)build older ones.
# That seems like a good tradeoff since we already have the older ones in release artifacts.


BOOST_FETCH_AND_CONFIGURE=$(cat << EOM
  # Boost is a 126 MB tarball, so, uh, let's not stick that in the repo.
  #
  # https://www.boost.org/doc/user-guide/getting-started.html#_individual_modules
  git clone https://github.com/boostorg/boost.git -b boost-1.87.0 boost_1_87_0 --depth 1
  cd boost_1_87_0
  git submodule update --depth 1 -q --init tools/boostdep
EOM
)

BOOST_LIBS="algorithm filesystem flyweight functional iostreams program_options python unordered"
for libname in $BOOST_LIBS; do
  echo "git submodule update --depth 1 -q --init libs/$libname" >> /tmp/xj-boost-cmds.txt
done
for libname in $BOOST_LIBS; do
  echo 'python3 tools/boostdep/depinst/depinst.py -X test -g "--depth 1"' $libname >> /tmp/xj-boost-cmds.txt
done
BOOST_FETCH_AND_CONFIGURE="$BOOST_FETCH_AND_CONFIGURE ; $(cat /tmp/xj-boost-cmds.txt)"
rm /tmp/xj-boost-cmds.txt


BOOST_BASE_BUILD_CMD='cmake -B build -S . -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DBOOST_IOSTREAMS_ENABLE_ZSTD=OFF'
#-DBOOST_ALL_NO_LIB=ON -DBOOST_ALL_DYN_LINK=ON'


SOUFFLE_FETCH_AND_CONFIGURE=$(cat << EOM
  git clone https://github.com/souffle-lang/souffle/
  cd souffle
  git switch 2.3 --detach

  # Some compilers have more warnings, which causes -Werror to induce failure
  sed -i.bak 's/-Werror //' src/CMakeLists.txt
EOM
)

# The specific commit here doesn't matter too much, just the LLVM version.
GET_XJ_LLVM_CLANG=$(cat << EOM
  wget https://github.com/Aarno-Labs/tenjin-build-deps/releases/download/rev-2523bdaf6/LLVM-${LLVM_FULL_VERSION}-$(uname -s)-$(uname -m | sed 's/arm64/aarch64/').tar.xz
  tar xf LLVM-*.tar.xz
  rm     LLVM-*.tar.xz
  mv LLVM-* xj-llvm
EOM
)


SCRIPTDIR=$(dirname $(realpath "$0"))
. $SCRIPTDIR/../../thirdparty-linux/common-vars.sh

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

  # Step 1: get prereqs for Souffle, Boost, and cclyzer
  #
  apt-get update && apt-get install --no-install-recommends python3 flex bison wget sqlite3 -y

  # Step 2: build Boost
  #
  mkdir localboost
  $BOOST_FETCH_AND_CONFIGURE

  $BOOST_BASE_BUILD_CMD -DCMAKE_INSTALL_PREFIX=/tmp/work/localboost
  cmake --build   build --parallel
  cmake --build   build --target install 

  du -sh /tmp/work/localboost

  ls -l /tmp/work/localboost/*

  # Step 3: build Souffle
  # 
  cd /tmp/work
  $SOUFFLE_FETCH_AND_CONFIGURE

  cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/tmp/work/localsouffle
  cmake --build build -- -j3   # full parallel build hit the OOM killer :(
  cmake --build build --target install

  cd /tmp/work
  # Step 4: get the right version of LLVM/Clang
  #
  $GET_XJ_LLVM_CLANG

  export PATH="\$PATH":/tmp/work/localsouffle/bin:/tmp/work/xj-llvm/bin

  # Step 5: build cclyzerpp
  #
  git clone https://github.com/brk/cclyzerpp
  cd cclyzerpp
  git switch tenjin # --detach d095a137891a999d2117fe751d6ac6dc7580f459
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLVM_MAJOR_VERSION=${LLVM_MAJOR_VERSION} -DLLVM_PARTIAL_VERSION=${LLVM_PARTIAL_VERSION} -DSOUFFLE_INCLUDE=/tmp/work/localsouffle/include/ -DBoost_ROOT=/tmp/work/localboost -DLLVM_DIR=/tmp/work/xj-llvm/lib/cmake/llvm

  cmake --build build -j 3 --target cc2json

  mkdir -p /outputs/bin
  cp build/cc2json /outputs/bin
  git log -n1 > /outputs/cclyzerpp-tenjin-HEAD-log.txt

  chown -R $(id -u):$(id -g) /outputs
EOF
################################################################################
        ;;

    Darwin*)
################################################################################
  TMPDIR=/tmp/xj-cclyzerpp
  rm -rf $TMPDIR
  mkdir $TMPDIR
  cd $TMPDIR

  # Build Boost
  echo "$BOOST_FETCH_AND_CONFIGURE" >> _b.sh
  echo "$BOOST_BASE_BUILD_CMD -DCMAKE_INSTALL_PREFIX=$TMPDIR/localboost" >> _b.sh
  echo cmake --build   build --parallel         >> _b.sh
  echo cmake --build   build --target install   >> _b.sh

  cat _b.sh
  wc -l _b.sh

  . _b.sh

  # Step 3: build Souffle
  #
  if [ -z "${CI:-}" ]; then
    echo "++++++++++++++++++++++++++++++++"
    echo "Since we're not in CI, I won't forcibly install new  brew  packages,"
    echo "   but if the commands below fail, try       brew install flex bison"
    echo "++++++++++++++++++++++++++++++++"
  else
    brew install flex bison
  fi
  cd $TMPDIR
  echo "$SOUFFLE_FETCH_AND_CONFIGURE" >> _s.sh

  echo cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$TMPDIR/localsouffle >> _s.sh
  echo cmake --build build -j3 >> _s.sh   # full parallel build hit the OOM killer :(
  echo cmake --build build --target install >> _s.sh
  . _s.sh

  # Step 4: get the right version of LLVM/Clang
  #
  cd $TMPDIR
  sh -c "$GET_XJ_LLVM_CLANG"

  export PATH=$TMPDIR/localsouffle/bin:$TMPDIR/xj-llvm/bin:"$PATH"


  # Step 5: build cclyzerpp
  #
  git clone https://github.com/brk/cclyzerpp
  cd cclyzerpp
  git switch tenjin # --detach d095a137891a999d2117fe751d6ac6dc7580f459
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLVM_MAJOR_VERSION=${LLVM_MAJOR_VERSION} -DLLVM_PARTIAL_VERSION=${LLVM_PARTIAL_VERSION} -DSOUFFLE_INCLUDE=$TMPDIR/localsouffle/include/ -DBoost_ROOT=$TMPDIR/localboost -DLLVM_DIR=$TMPDIR/xj-llvm/lib/cmake/llvm -DSOUFFLE_USE_LIBFFI=OFF -DCMAKE_C_COMPILER=$(which clang) -DCMAKE_CXX_COMPILER=$(which clang++) -DOpenMP_CXX_FLAGS="-fopenmp" -DOpenMP_CXX_INCLUDE_DIR="$TMPDIR/xj-llvm/lib/clang/${LLVM_MAJOR_VERSION}/include/" -DOpenMP_CXX_LIB_NAMES=""

  cmake --build build --parallel --target cc2json

  mkdir -p $OUTDIR/bin/
  cp build/cc2json $OUTDIR/bin/
  git log -n1 > $OUTDIR/cclyzerpp-tenjin-HEAD-log.txt

  cd ..
  rm -rf $TMPDIR
################################################################################
        ;;

    *)
        echo "Running on an unknown OS: ${OS_NAME}"
        # Handle other operating systems or provide a default action
        ;;
esac

