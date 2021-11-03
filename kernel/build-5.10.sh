#!/bin/bash

KERNEL_VERSION="5.10.77"
PATCH_VERSION="5.10.73-rt54"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.10"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.10-rt"
CONFIG_NO_RT="${SCRIPT_DIR}/config-5.10-no-rt"
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup
