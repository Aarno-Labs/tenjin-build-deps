# Instructions

## New Third Party Dependency

1. Add a new subdirectory within `thirdparty/` containing a tarball and `build-via-container.sh`
1. Update `README.md`
1. Test the build locally by running `cd thirdparty ; mkdir -p out/{bin,lib,include} ; bash NEWTOOL/build-via-container.sh` and check that `out/` contains what you want it to. Iterate to satisfaction.
1. Commit and push.
1. Navigate to the Actions tab on GitHub. Click "build and release non-LLVM deps" on the left. Click the "Run workflow" button on the right. This will take 4-ish minutes.
1. Update the referenced tag for `10j-build-deps` and `10j-bullseye-sysroot-extras` in `cli/constants.py` in the Tenjin repository.

## Tweaks to LLVM (or new LLVM version)

As above, but skip the first three steps.

- It's probably easiest to test build system tweaks by repeatedly building via CI.
  Please do this in a forked repo or branch.
- When testing with the [BuildLLVM](https://github.com/Aarno-Labs/tenjin-build-deps/actions/workflows/buildllvm.yml) action, leave the "Upload to release tag" field empty.
- If a release already exists that does not have the LLVM version(s) being generated,
  it can be used as the target release. Otherwise, make a new release first.
- For LLVM-only releases, one can also manually create an empty release on GitHub
  to hold the built artifacts. Use a release & tag name akin to `tenjin-llvm-123456789`
  with the last part being a 9-digit prefix of a commit from `@Aarno-Labs/llvm-project`
  and be sure to unmark the "Set as the latest release" checkbox. I also mark these as
  "pre-releases" but that's just aesthetic.

