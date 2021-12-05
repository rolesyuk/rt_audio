#!/bin/bash

# this script builds DEBs for WINE NSPA https://github.com/nine7nine/pkgbuilds_nspa

# this script does NOT handle WINE build dependencies for amd64 (WINE64) and i386 (WINE32)
# install them as in https://wiki.winehq.org/Building_Wine#Satisfying_Build_Dependencies
# for the tip see ./configure output at the end, unmet dependencies are shown
# for this script to work 'checkinstall' package is needed

CONFIG=3

WINE_BUILD_OPTIONS=

WORKING_DIR="${PWD}"
SCRIPT_DIR="$(dirname `readlink -f "${0}"`)"

PATCHES=()
if [ "${CONFIG}" -eq 0 ]; then
	INTERACTIVE=0
	BUILD_STAGING=1
	BUILD_NSPA=1
	BUILD_FROM_GIT=0
	PKG_NAME=wine-nspa
	PKG_VER=5.9
	PKG_REL=19
	WINE_TAR_SOURCE="https://dl.winehq.org/wine/source/5.x/wine-${PKG_VER}.tar.xz"
	NSPA_SOURCE="https://github.com/nine7nine/pkgbuilds_nspa/archive/a8918eaeed364caf792d0bec80092c142f37c30f.zip"
	NSPA_DIR="${WORKING_DIR}/pkgbuilds_nspa-$(basename ${NSPA_SOURCE} | awk -F '.' '{print $1}')"
elif [ "${CONFIG}" -eq 1 ]; then
	INTERACTIVE=0
	BUILD_STAGING=0
	BUILD_NSPA=0
	BUILD_FROM_GIT=1
	PKG_NAME=wine-proton-exp
	PKG_VER=6.3
	PKG_REL=0
	WINE_BUILD_OPTIONS="--without-ldap --without-curses --without-oss --disable-winemenubuilder --disable-win16 --disable-tests"
	WINE_GIT_SOURCE="https://github.com/ValveSoftware/wine.git"
	WINE_GIT_BRANCH="experimental_6.3"
elif [ "${CONFIG}" -eq 2 ]; then
	INTERACTIVE=0
	BUILD_STAGING=0
	BUILD_NSPA=0
	BUILD_FROM_GIT=0
	PKG_NAME=wine-devel-cef-fsync
	PKG_VER=6.22
	PKG_REL=0
	WINE_TAR_SOURCE="https://dl.winehq.org/wine/source/6.x/wine-${PKG_VER}.tar.xz"
	PATCHES+=("${SCRIPT_DIR}/esync-unix-mainline.patch"
		  "${SCRIPT_DIR}/fsync-unix-mainline.patch"
		  "${SCRIPT_DIR}/fsync_futex_waitv.patch")
elif [ "${CONFIG}" -eq 3 ]; then
	INTERACTIVE=0
	BUILD_STAGING=0
	BUILD_NSPA=0
	BUILD_FROM_GIT=0
	PKG_NAME=wine-stable-cef-fsync
	PKG_VER=6.0.2
	PKG_REL=0
	WINE_TAR_SOURCE="https://dl.winehq.org/wine/source/6.0/wine-${PKG_VER}.tar.xz"
	PATCHES+=("${SCRIPT_DIR}/fsync-6.0.patch"
		  "${SCRIPT_DIR}/fsync_futex_waitv.patch")
else
	echo "No such configuration. Exiting..."
	exit -1
fi

WINE_DIR="${WORKING_DIR}/wine-${PKG_VER}"
WINE_STAGING_SOURCE="https://github.com/wine-staging/wine-staging/archive/v${PKG_VER}.tar.gz"
WINE_STAGING_DIR="${WORKING_DIR}/wine-staging-${PKG_VER}"

# fixes BIAS FX 2 GUI not-showing isssue
# for details see https://linuxmusicians.com/viewtopic.php?t=20660&p=111944
PATCHES+=("${SCRIPT_DIR}/cef.patch")

if [ "${BUILD_FROM_GIT}" -eq 1 ]; then
	if [ ! -d "${WINE_DIR}" ]; then
		git clone -b "${WINE_GIT_BRANCH}" "${WINE_GIT_SOURCE}" "${WINE_DIR}" || exit -1
	else
		cd "${WINE_DIR}"
		git clean -xdf
		git reset --hard
		git checkout "${WINE_GIT_BRANCH}"
		git pull || exit -1
	fi
	DPKG_SOURCE="${WINE_GIT_SOURCE}"
else
	if [ ! -r $(basename "${WINE_TAR_SOURCE}") ]; then
		wget -c "${WINE_TAR_SOURCE}" || exit -1
	fi
	rm -rf "${WINE_DIR}"
	tar -xJf $(basename "${WINE_TAR_SOURCE}") || exit -1
	DPKG_SOURCE="${WINE_TAR_SOURCE}"
fi

if [ "${BUILD_STAGING}" -eq 1 ]; then
	if [ ! -r $(basename "${WINE_STAGING_SOURCE}") ]; then
		wget -c "${WINE_STAGING_SOURCE}" || exit -1
	fi
	rm -rf "${WINE_STAGING_DIR}"
	tar -xzf $(basename "${WINE_STAGING_SOURCE}") || exit -1

	# apply wine-staging patchset
	pushd "${WINE_STAGING_DIR}/patches"
		./patchinstall.sh DESTDIR="${WINE_DIR}" --all || exit -1
	popd
	DPKG_SOURCE="${WINE_STAGING_SOURCE}"
fi

if [ "${BUILD_NSPA}" -eq 1 ]; then
	if [ ! -r $(basename "${NSPA_SOURCE}") ]; then
		wget -c "${NSPA_SOURCE}" || exit -1
	fi
	rm -rf "${NSPA_DIR}"
	unzip $(basename "${NSPA_SOURCE}") || exit -1

	# apply nspa patchset
	cd ${WINE_DIR}
	N=1
	grep -E '^ *patch' ${NSPA_DIR}/wine-nspa/PKGBUILD | sed 's/srcdir/{NSPA_DIR}\/wine-nspa/' | while read PATCH; do
		echo "$(printf '%02d:' ${N}) $(eval echo ${PATCH})"
		N=$((N+1))
		eval "${PATCH}"
	done
	DPKG_SOURCE="${NSPA_SOURCE}"
fi

cd ${WINE_DIR}

# get rid of the old build dirs
rm -rf ${PKG_NAME}-{32,64}-build
mkdir ${PKG_NAME}-{32,64}-build

# apply custom patches
N=1
for PATCH in ${PATCHES[@]}; do
	echo "$(printf '%02d:' ${N}) ${PATCH}"
	N=$((N+1))
	patch -p1 < "${PATCH}" || exit -1
done

function print_interactive {
	echo
	echo "${1}"
	if [ "${INTERACTIVE}" -ne 0 ]; then
		echo "Press ENTER to continue ..."
		read
	fi
}

print_interactive "Starting configure WINE ..."
cd "${WINE_DIR}"
dlls/winevulkan/make_vulkan
tools/make_requests
autoreconf -f

print_interactive "Starting configure WINE64 ..."
cd "${WINE_DIR}/${PKG_NAME}-64-build"
../configure --prefix=/opt/${PKG_NAME} --enable-win64 --with-mingw=no ${WINE_BUILD_OPTIONS} || exit -1

print_interactive "Starting build WINE64 ..."
make -j$(nproc) || exit -1

print_interactive "Starting configure WINE32 ..."
cd "${WINE_DIR}/${PKG_NAME}-32-build"
../configure --prefix=/opt/${PKG_NAME} --with-wine64="${WINE_DIR}/${PKG_NAME}-64-build" --with-mingw=no ${WINE_BUILD_OPTIONS} || exit -1

print_interactive "Starting build WINE32 ..."
make -j$(nproc) || exit -1

function do_checkinstall {
	sudo checkinstall \
		--exclude \
		--nodoc \
		--pkgversion="${PKG_VER}" \
		--pkgrelease="${PKG_REL}" \
		--pkgsource="${DPKG_SOURCE}" \
		--requires="libasound2 \(\>= 1.0.16\), libc6 \(\>= 2.29\), libfaudio0 \(\>= 19.06.07\), libgcc-s1 \(\>= 3.0\), libglib2.0-0 \(\>= 2.12.0\), libgphoto2-6 \(\>= 2.5.10\), libgphoto2-port12 \(\>= 2.5.10\), libgstreamer-plugins-base1.0-0 \(\>= 1.0.0\), libgstreamer1.0-0 \(\>= 1.4.0\), liblcms2-2 \(\>= 2.2+git20110628\), libldap-2.4-2 \(\>= 2.4.7\), libmpg123-0 \(\>= 1.13.7\), libopenal1 \(\>= 1.14\), libpulse0 \(\>= 0.99.1\), libudev1 \(\>= 183\), libusb-1.0-0 \(\>= 2:1.0.21\), libvkd3d1 \(\>= 1.0\), libx11-6, libxext6, libxml2 \(\>= 2.9.0\), libasound2-plugins, libncurses6 \| libncurses5 \| libncurses" \
		--pkgarch=${1} \
		--default
}

print_interactive "Starting install with checkinstall ..."
cd "${WINE_DIR}/${PKG_NAME}-64-build"
do_checkinstall amd64
cd "${WINE_DIR}/${PKG_NAME}-32-build"
do_checkinstall i386
