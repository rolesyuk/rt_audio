#!/bin/bash

# this script build DEBs for WINE NSPA https://github.com/nine7nine/pkgbuilds_nspa

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

WINE_SOURCE="https://dl.winehq.org/wine/source/5.x/wine-${PKG_VER}.tar.xz"
WINE_STAGING_SOURCE="https://github.com/wine-staging/wine-staging/archive/v${PKG_VER}.tar.gz"
NSPA_SOURCE="https://github.com/nine7nine/pkgbuilds_nspa/archive/4b29025f3b337c328373f2d4deb5d15397b9f26e.zip"

WORKING_DIR="${PWD}"
SCRIPT_DIR="$(dirname `readlink -f "${0}"`)"
WINE_DIR="${WORKING_DIR}/wine-${PKG_VER}"
WINE_STAGING_DIR="${WORKING_DIR}/wine-staging-${PKG_VER}"
NSPA_DIR="${WORKING_DIR}/pkgbuilds_nspa-$(basename ${NSPA_SOURCE} | awk -F '.' '{print $1}')"

# fixes BIAS FX 2 GUI not-showing isssue
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
grep 'patch -s' ${NSPA_DIR}/wine-nspa/PKGBUILD | sed 's/srcdir/{NSPA_DIR}\/wine-nspa/' | while read PATCH; do
	echo "Applying $(eval echo ${PATCH}) ..."
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

print_interactive "Starting install with checkinstall ..."
cd "${WINE_DIR}/${PKG_NAME}-64-build"
sudo checkinstall
cd "${WINE_DIR}/${PKG_NAME}-32-build"
sudo checkinstall
