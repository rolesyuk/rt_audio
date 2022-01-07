#!/bin/bash

KERNEL_VERSION="5.15.13"
PATCH_VERSION="5.15.12-rt25"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.15"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.15-rt"
CONFIG_NO_RT=""
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup
