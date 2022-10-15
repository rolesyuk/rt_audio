#!/bin/bash

KERNEL_VERSION="5.18.2"
PATCH_VERSION="5.18-rt11"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.18"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.18-rt"
CONFIG_NO_RT=""
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build.sh"

download
build rt opt
cleanup