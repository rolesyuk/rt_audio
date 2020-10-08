#!/bin/bash

KERNEL_VERSION="5.4.69"
PATCH_VERSION="5.4.69-rt39"

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.4"

SCRIPT_DIR="$(dirname `readlink -f $0`)"
CONFIG_RT="${SCRIPT_DIR}/config-5.4-rt"
CONFIG_NO_RT="${SCRIPT_DIR}/config-5.4-no-rt"

mkdir -p "${KERNEL_VERSION}"

function build_kernel {
	rm -rf "linux-${KERNEL_VERSION}"
	tar -xf "linux-${KERNEL_VERSION}.tar"

	cd "linux-${KERNEL_VERSION}"
	if [ "${1}" == "fwm-rt" ]; then
		patch -p1 < ../"patch-${PATCH_VERSION}.patch" || exit -1
		cp "${CONFIG_RT}" .config || exit -1
	elif [ "${1}" == "fwm" ]; then
		cp "${CONFIG_NO_RT}" .config || exit -1
	else
		exit -1
	fi
	patch -p1 < "${SCRIPT_DIR}/futex-wait-multiple-5.5-deadlock_fix.patch" || exit -1
	yes "" | make oldconfig
	make EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
	cd ..

	rm -rf "linux-${KERNEL_VERSION}"
}

(cd "${KERNEL_VERSION}"

wget -c "${KERNEL_URL}/linux-${KERNEL_VERSION}.tar.xz"
wget -c "${KERNEL_URL}/linux-${KERNEL_VERSION}.tar.sign"
wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.xz"
wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.sign"

unxz -k "linux-${KERNEL_VERSION}.tar.xz"
unxz -k "patch-${PATCH_VERSION}.patch.xz"
gpg --verify "linux-${KERNEL_VERSION}.tar.sign" "linux-${KERNEL_VERSION}.tar" || exit -1
gpg --verify "patch-${PATCH_VERSION}.patch.sign" "patch-${PATCH_VERSION}.patch" || exit -1

build_kernel fwm-rt
build_kernel fwm

ls | grep -vE 'headers|image' | xargs rm
)
