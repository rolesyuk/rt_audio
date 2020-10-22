function download {
	mkdir -p "${SCRIPT_DIR}/${KERNEL_VERSION}"
	cd "${SCRIPT_DIR}/${KERNEL_VERSION}"
	
	wget -c "${KERNEL_URL}/linux-${KERNEL_VERSION}.tar.xz"
	wget -c "${KERNEL_URL}/linux-${KERNEL_VERSION}.tar.sign"
	wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.xz"
	wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.sign"
	
	unxz -k "linux-${KERNEL_VERSION}.tar.xz"
	unxz -k "patch-${PATCH_VERSION}.patch.xz"
	gpg --verify "linux-${KERNEL_VERSION}.tar.sign" "linux-${KERNEL_VERSION}.tar" || exit -1
	gpg --verify "patch-${PATCH_VERSION}.patch.sign" "patch-${PATCH_VERSION}.patch" || exit -1
}

function build {
	cd "${SCRIPT_DIR}/${KERNEL_VERSION}"
	rm -rf "linux-${KERNEL_VERSION}"
	tar -xf "linux-${KERNEL_VERSION}.tar"
	cd "linux-${KERNEL_VERSION}"

	if [ "${2}" == "opt" ]; then
		export KCFLAGS="-march=native" KCPPFLAGS="-march=native"
		sed -i 's/-mtune=generic/-march=native/' arch/x86/Makefile
		sed -i   's/-march=core2/-march=native/' arch/x86/Makefile
	fi

	if   [ "${1}" == "rt" ]; then
		patch -p1 < ../"patch-${PATCH_VERSION}.patch" || exit -1
		cp "${CONFIG_RT}" .config || exit -1
		yes "" | make oldconfig
		if [ "${2}" == "opt" ]; then
			make CC="${COMPILER}" -j$(nproc) deb-pkg || exit -1
		else
			make -j$(nproc) deb-pkg || exit -1
		fi
	elif [ "${1}" == "fwm-rt" ]; then
		patch -p1 < ../"patch-${PATCH_VERSION}.patch" || exit -1
		patch -p1 < "${SCRIPT_DIR}/futex-wait-multiple-5.5-deadlock_fix.patch" || exit -1
		cp "${CONFIG_RT}" .config || exit -1
		yes "" | make oldconfig
		if [ "${2}" == "opt" ]; then
			make CC="${COMPILER}" EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
		else
			make EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
		fi
	elif [ "${1}" == "fwm" ]; then
		patch -p1 < "${SCRIPT_DIR}/futex-wait-multiple-5.5-deadlock_fix.patch" || exit -1
		cp "${CONFIG_NO_RT}" .config || exit -1
		yes "" | make oldconfig
		if [ "${2}" == "opt" ]; then
			make CC="${COMPILER}" EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
		else
			make EXTRAVERSION=-fwm -j$(nproc) deb-pkg || exit -1
		fi
	else
		exit -1
	fi

	cd ..
	rm -rf "linux-${KERNEL_VERSION}"
}

function cleanup {
	cd "${SCRIPT_DIR}/${KERNEL_VERSION}"
	ls | grep -vE 'headers|image' | xargs rm
}
