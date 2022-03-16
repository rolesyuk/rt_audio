#!/bin/bash

KERNEL_VERSION="5.17-rc8"
PATCH_VERSION="5.17-rc8-rt14"
KERNEL_URL="https://git.kernel.org/torvalds/t"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.17"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.17-rt"
CONFIG_NO_RT=""
COMPILER="/usr/bin/gcc-11"

source "${SCRIPT_DIR}/build-rc.sh"

download
build rt opt
cleanup
