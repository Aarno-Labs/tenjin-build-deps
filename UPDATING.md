# Instructions

## New Third Party Dependency

1. Add a new subdirectory within `thirdparty/` containing a tarball and `build-via-container.sh`
1. Update `README.md`
1. Test the build locally by running `cd thirdparty ; mkdir -p out/bin ; bash NEWTOOL/build-via-container.sh` and check that `out/` contains what you want it to. Iterate to satisfaction.
1. Commit and push.
1. Navigate to the Actions tab on GitHub. Click "build and release non-LLVM deps" on the left. Click the "Run workflow" button on the right. This will take 4-ish minutes.
1. Update the referenced tag for `10j-build-deps` and `10j-bullseye-sysroot-extras` in `cli/constants.py` in the Tenjin repository.

