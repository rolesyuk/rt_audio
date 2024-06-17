#!/bin/bash

KERNEL_VERSION="6.1.94"
PATCH_VERSION="6.1.92-rt32"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.1"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-6.1-rt"
CONFIG_NO_RT=""
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup
