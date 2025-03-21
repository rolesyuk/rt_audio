#!/bin/bash

KERNEL_VERSION="6.12.19"
PATCH_VERSION="6.12.16-rt9"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/6.12"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-6.12-rt"
CONFIG_NO_RT=""
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup
