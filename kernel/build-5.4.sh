#!/bin/bash

KERNEL_VERSION="5.4.72"
PATCH_VERSION="5.4.70-rt40"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.4"
SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.4-rt"
CONFIG_NO_RT="${SCRIPT_DIR}/config-5.4-no-rt"

source "${SCRIPT_DIR}/build.sh"

download
build rt
build fwm-rt
build fwm
cleanup
