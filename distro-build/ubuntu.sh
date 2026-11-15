# After changing, update the DISTRO_NAME below.
dist_version="26.04"
dist_codename="resolute"

bootstrap_distribution() {
	sudo rm -f "${ROOTFS_DIR}"/ubuntu-*-"${dist_version}".tar.xz

	for arch in arm64 armhf amd64; do
		if should_skip_arch "$arch"; then
			echo "[*] Skipping architecture: $(translate_arch "$arch")"
			continue
		fi

		target_dir="${WORKDIR}/ubuntu-${dist_codename}-$(translate_arch "$arch")"
		sudo rm -rf "${target_dir}"

		sudo DEBIAN_FRONTEND=noninteractive mmdebstrap \
			--architectures=${arch} \
			--variant=apt \
			--components="main,universe,multiverse" \
			--include="locales,passwd,software-properties-common,sudo" \
			--format=directory \
			"${dist_codename}" \
			"${target_dir}"

		cat <<-EOF | sudo unshare -mpf bash -e -
			export DEBIAN_FRONTEND=noninteractive
			mount --bind /dev "${target_dir}/dev"
			mount --bind /proc "${target_dir}/proc"
			mount --bind /sys "${target_dir}/sys"

			chroot "${target_dir}" apt-get update
			# Swap uutils to GNU coreutils in a single atomic transaction
			chroot "${target_dir}" apt-get install -yq --allow-remove-essential \
				coreutils-from-gnu \
				gnu-coreutils \
				coreutils-from-uutils-
			chroot "${target_dir}" apt-get autoremove --purge -yq
			chroot "${target_dir}" apt-get clean
			rm -rf "${target_dir}/var/lib/apt/lists/"*
		EOF

		archive_rootfs "${ROOTFS_DIR}/ubuntu-$(translate_arch "$arch")-${dist_version}.tar.xz" \
			"ubuntu-${dist_codename}-$(translate_arch "$arch")"
	done
	unset arch
}
