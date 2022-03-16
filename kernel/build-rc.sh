source $(dirname `readlink -f $0`)/build.sh

function download {
	mkdir -p "${SCRIPT_DIR}/${KERNEL_VERSION}"
	cd "${SCRIPT_DIR}/${KERNEL_VERSION}"
	
	wget -c "${KERNEL_URL}/linux-${KERNEL_VERSION}.tar.gz"
	wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.xz"
	wget -c "${PATCH_URL}/patch-${PATCH_VERSION}.patch.sign"
	
	gunzip -kf "linux-${KERNEL_VERSION}.tar.gz"
	unxz -k "patch-${PATCH_VERSION}.patch.xz"
	gpg --verify "patch-${PATCH_VERSION}.patch.sign" "patch-${PATCH_VERSION}.patch" || exit -1
}
