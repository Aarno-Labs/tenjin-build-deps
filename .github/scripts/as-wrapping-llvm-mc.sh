#!/bin/sh

# Shout out to https://briancallahan.net/blog/20240122.html

args=""
for arg in "$@"; do
    case "$arg" in
        "--64")
            arch=$(uname -m)
            if [ "$arch" = "arm64" ]; then
                args="$args --arch=arm64"
            else
                args="$args --arch=x86-64"
            fi
            ;;
        "--32")
            args="$args --arch=x86"
            ;;
        "-v")
            # Skip -v flag
            ;;
        *)
            args="$args $arg"
            ;;
    esac
done

exec llvm-mc --filetype=obj $args
