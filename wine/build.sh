#!/bin/bash

# this script builds DEBs for WINE NSPA https://github.com/nine7nine/pkgbuilds_nspa

# this script does NOT handle WINE build dependencies for amd64 (WINE64) and i386 (WINE32)
# install them as in https://wiki.winehq.org/Building_Wine#Satisfying_Build_Dependencies
# for the tip see ./configure output at the end, unmet dependencies are shown
# for this script to work 'checkinstall' package is needed

INTERACTIVE=0

function print_interactive {
	echo
	echo "${1}"
	if [ "${INTERACTIVE}" -ne 0 ]; then
		echo "Press ENTER to continue ..."
		read
	fi
}

PKG_NAME=wine-nspa
PKG_VER=5.9
PKG_REL=15

WINE_SOURCE="https://dl.winehq.org/wine/source/5.x/wine-${PKG_VER}.tar.xz"
WINE_STAGING_SOURCE="https://github.com/wine-staging/wine-staging/archive/v${PKG_VER}.tar.gz"
NSPA_SOURCE="https://github.com/nine7nine/pkgbuilds_nspa/archive/e18560b144f3e882d7d166c1072b493a7569c9a1.zip"

WORKING_DIR="${PWD}"
SCRIPT_DIR="$(dirname `readlink -f "${0}"`)"
WINE_DIR="${WORKING_DIR}/wine-${PKG_VER}"
WINE_STAGING_DIR="${WORKING_DIR}/wine-staging-${PKG_VER}"
NSPA_DIR="${WORKING_DIR}/pkgbuilds_nspa-$(basename ${NSPA_SOURCE} | awk -F '.' '{print $1}')"

# fixes BIAS FX 2 GUI not-showing isssue
# for details see https://linuxmusicians.com/viewtopic.php?t=20660&p=111944
PATCHES=("${SCRIPT_DIR}/cef.patch")

if [ ! -r $(basename "${WINE_SOURCE}") ]; then
	wget -c "${WINE_SOURCE}" || exit -1
fi
rm -rf "${WINE_DIR}"
tar -xJf $(basename "${WINE_SOURCE}") || exit -1

if [ ! -r $(basename "${WINE_STAGING_SOURCE}") ]; then
	wget -c "${WINE_STAGING_SOURCE}" || exit -1
fi
rm -rf "${WINE_STAGING_DIR}"
tar -xzf $(basename "${WINE_STAGING_SOURCE}") || exit -1

if [ ! -r $(basename "${NSPA_SOURCE}") ]; then
	wget -c "${NSPA_SOURCE}" || exit -1
fi
rm -rf "${NSPA_DIR}"
unzip $(basename "${NSPA_SOURCE}") || exit -1

cd ${WINE_DIR}

# apply wine-staging patchset
pushd "${WINE_STAGING_DIR}/patches"
./patchinstall.sh DESTDIR="${WINE_DIR}" --all || exit -1
popd

# get rid of old build dirs
rm -rf ${PKG_NAME}-{32,64}-build
mkdir ${PKG_NAME}-{32,64}-build

# apply nspa patchset
N=1
grep -E '^ *patch' ${NSPA_DIR}/wine-nspa/PKGBUILD | sed 's/srcdir/{NSPA_DIR}\/wine-nspa/' | while read PATCH; do
	echo "$(printf '%02d:' ${N}) $(eval echo ${PATCH})"
	N=$((N+1))
	eval "${PATCH}"
done

# apply cef patch
for PATCH in ${PATCHES[@]}; do
	patch -p1 < "${PATCH}" || exit -1
done

print_interactive "Starting configure WINE64 ..."
cd "${WINE_DIR}/${PKG_NAME}-64-build"
../configure --prefix=/opt/${PKG_NAME} --enable-win64 || exit -1

print_interactive "Starting build WINE64 ..."
make -j$(nproc) || exit -1

print_interactive "Starting configure WINE32 ..."
cd "${WINE_DIR}/${PKG_NAME}-32-build"
../configure --prefix=/opt/${PKG_NAME} --with-wine64="${WINE_DIR}/${PKG_NAME}-64-build" || exit -1

print_interactive "Starting build WINE32 ..."
make -j$(nproc) || exit -1

function do_checkinstall {
	sudo checkinstall \
		--exclude \
		--nodoc \
		--pkgversion="${PKG_VER}" \
		--pkgrelease="${PKG_REL}" \
		--pkgsource="${NSPA_SOURCE}" \
		--requires="libasound2 \(\>= 1.0.16\), libc6 \(\>= 2.29\), libfaudio0 \(\>= 19.06.07\), libgcc-s1 \(\>= 3.0\), libglib2.0-0 \(\>= 2.12.0\), libgphoto2-6 \(\>= 2.5.10\), libgphoto2-port12 \(\>= 2.5.10\), libgstreamer-plugins-base1.0-0 \(\>= 1.0.0\), libgstreamer1.0-0 \(\>= 1.4.0\), liblcms2-2 \(\>= 2.2+git20110628\), libldap-2.4-2 \(\>= 2.4.7\), libmpg123-0 \(\>= 1.13.7\), libopenal1 \(\>= 1.14\), libpulse0 \(\>= 0.99.1\), libudev1 \(\>= 183\), libusb-1.0-0 \(\>= 2:1.0.21\), libvkd3d1 \(\>= 1.0\), libx11-6, libxext6, libxml2 \(\>= 2.9.0\), libasound2-plugins, libncurses6 \| libncurses5 \| libncurses" \
		--pkgarch=${1} \
		--default
}

print_interactive "Starting install with checkinstall ..."
cd "${WINE_DIR}/${PKG_NAME}-64-build"
do_checkinstall amd64
cd "${WINE_DIR}/${PKG_NAME}-32-build"
do_checkinstall i386
