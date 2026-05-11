#!/usr/bin/env python3

import os
import shutil
import subprocess
import sys


def main() -> int:
    if len(sys.argv) != 1:
        print(f"usage: {sys.argv[0]}", file=sys.stderr)
        return 1

    input_os = os.environ.get("INPUT_OS")
    if input_os is None:
        print("INPUT_OS is not set", file=sys.stderr)
        return 1

    os_name = input_os.lower()
    if os_name == "macos" and shutil.which("ninja") is not None:
        print("ninja is already installed")
        return 0

    command_by_os = {
        "linux": "sudo apt-get install -y ninja-build",
        "ubuntu": "sudo apt-get install -y ninja-build",
        "windows": "pip install ninja",
        "macos": "brew install ninja",
    }
    command = command_by_os.get(os_name)
    if command is None:
        print(f"Unknown os: {os_name}", file=sys.stderr)
        return 1

    completed = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True,
        check=False,
    )
    print(completed.stdout, end="")
    print(completed.stderr, end="", file=sys.stderr)
    return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
