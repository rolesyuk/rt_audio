#!/bin/bash

KERNEL_VERSION="5.4.83"
PATCH_VERSION="5.4.82-rt45"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.4"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.4-rt"
CONFIG_NO_RT="${SCRIPT_DIR}/config-5.4-no-rt"
COMPILER="/usr/bin/gcc-10"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup
