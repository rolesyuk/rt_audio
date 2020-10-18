#!/bin/bash

KERNEL_VERSION="5.9.1"
PATCH_VERSION="5.9-rt16"

KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x"
PATCH_URL="https://cdn.kernel.org/pub/linux/kernel/projects/rt/5.9"

SCRIPT_DIR="$(dirname `readlink -f $0`)"

CONFIG_RT="${SCRIPT_DIR}/config-5.9-rt"
CONFIG_NO_RT="${SCRIPT_DIR}/config-5.9-no-rt"

COMPILER="/usr/bin/gcc-10" 

mkdir -p "${KERNEL_VERSION}"

function build_kernel {
	rm -rf "linux-${KERNEL_VERSION}"
	tar -xf "linux-${KERNEL_VERSION}.tar"
	cd "linux-${KERNEL_VERSION}"

	export KCFLAGS="-march=native" KCPPFLAGS="-march=native"
	sed -i 's/-mtune=generic/-march=native/' arch/x86/Makefile

	if   [ "${1}" == "rt" ]; then
		patch -p1 < ../"patch-${PATCH_VERSION}.patch" || exit -1
		cp "${CONFIG_RT}" .config || exit -1
		yes "" | make oldconfig
		make CC="${COMPILER}" -j$(nproc) deb-pkg || exit -1
	elif [ "${1}" == "fwm-rt" ]; then
		patch -p1 < ../"patch-${PATCH_VERSION}.patch" || exit -1
		patch -p1 < "${SCRIPT_DIR}/futex-wait-multiple-5.5-deadlock_fix.patch" || exit -1
		cp "${CONFIG_RT}" .config || exit -1
		yes "" | make oldconfig
		make CC="${COMPILER}" EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
	elif [ "${1}" == "fwm" ]; then
		patch -p1 < "${SCRIPT_DIR}/futex-wait-multiple-5.5-deadlock_fix.patch" || exit -1
		cp "${CONFIG_NO_RT}" .config || exit -1
		yes "" | make oldconfig
		make CC="${COMPILER}" EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
	else
		exit -1
	fi

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

build_kernel rt
#build_kernel fwm-rt
#build_kernel fwm

ls | grep -vE 'headers|image' | xargs rm
)
