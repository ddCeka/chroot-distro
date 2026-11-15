dist_version="2026.10.01"

bootstrap_distribution() {
	sudo rm -f "${ROOTFS_DIR}"/archlinux-*.tar.xz

	local bootstrap_ready=false

	# Build x86_64 before i686 to ensure bootstrap config is not tainted for x86_64
	for arch in aarch64 armv7 x86_64 i686; do
		if should_skip_arch "$arch"; then
			echo "[*] Skipping architecture: $(translate_arch "$arch")"
			continue
		fi

		case "$arch" in
		aarch64 | armv7)
			curl --fail --location \
				--output "${WORKDIR}/archlinux-${arch}.tar.gz" \
				"http://os.archlinuxarm.org/os/ArchLinuxARM-${arch}-latest.tar.gz"

			target_dir="${WORKDIR}/archlinux-$(translate_arch "$arch")"
			sudo rm -rf "${target_dir}"
			sudo mkdir -m 755 "${target_dir}"
			sudo tar -zxp --warning=no-unknown-keyword --acls --xattrs --xattrs-include='*' \
				-f "${WORKDIR}/archlinux-${arch}.tar.gz" \
				-C "${target_dir}"

			# Disable pacman sandbox before any pacman operations (Landlock not supported in CI/QEMU)
			sudo sed -i 's/#DisableSandbox/DisableSandbox/' "${target_dir}/etc/pacman.conf"

			cat <<-EOF | sudo unshare -mpf bash -e -
				rm -f "${target_dir}/etc/resolv.conf"
				echo "nameserver 1.1.1.1" > "${target_dir}/etc/resolv.conf"
				mount --bind "${target_dir}/" "${target_dir}/"
				mount --rbind /dev "${target_dir}/dev"
				mount --make-rslave "${target_dir}/dev"
				mount --bind /proc "${target_dir}/proc"
				mount --bind /sys "${target_dir}/sys"
				chroot "${target_dir}" pacman-key --init
				chroot "${target_dir}" pacman-key --populate archlinuxarm

				# Remove kernel and firmware to save space (not needed in chroot)
				if [ "$arch" = "aarch64" ]; then
					chroot "${target_dir}" pacman -Rnsc --noconfirm linux-aarch64 linux-firmware || true
				else
					chroot "${target_dir}" pacman -Rnsc --noconfirm linux-armv7 linux-firmware || true
				fi

				# Retry upgrade in case of transient mirror 404s
				for attempt in 1 2 3; do
					if chroot "${target_dir}" pacman -Syyu --noconfirm; then
						break
					fi
					if [ "\$attempt" -eq 3 ]; then
						echo "Error: pacman upgrade failed after 3 attempts"
						exit 1
					fi
					echo "[*] Retry \$attempt: pacman upgrade failed, retrying in 30s..."
					sleep 30
				done
				chroot "${target_dir}" pacman -S --noconfirm sudo
				# Stop gpg-agent inside chroot so socket files don't linger during tar
				chroot "${target_dir}" pkill -9 gpg-agent || true
			EOF
			;;
		x86_64 | i686)
			if [ "$bootstrap_ready" = "false" ]; then
				curl --fail --location \
					--output "${WORKDIR}/archlinux-x86_64.tar.zst" \
					"https://mirror.rackspace.com/archlinux/iso/${dist_version}/archlinux-bootstrap-${dist_version}-x86_64.tar.zst"

				sudo mkdir -m 755 "${WORKDIR}/archlinux-bootstrap"
				sudo tar -xp --strip-components=1 --acls --xattrs --xattrs-include='*' \
					-f "${WORKDIR}/archlinux-x86_64.tar.zst" \
					-C "${WORKDIR}/archlinux-bootstrap"

				# Disable pacman sandbox in bootstrap environment
				sudo sed -i 's/#DisableSandbox/DisableSandbox/' "${WORKDIR}/archlinux-bootstrap/etc/pacman.conf"

				# Configure bootstrap environment once
				cat <<-EOF | sudo unshare -mpf bash -e -
					rm -f "${WORKDIR}/archlinux-bootstrap/etc/resolv.conf"
					echo "nameserver 1.1.1.1" > "${WORKDIR}/archlinux-bootstrap/etc/resolv.conf"
					mount --bind "${WORKDIR}/archlinux-bootstrap/" "${WORKDIR}/archlinux-bootstrap/"
					mount --bind /dev "${WORKDIR}/archlinux-bootstrap/dev"
					mount --bind /proc "${WORKDIR}/archlinux-bootstrap/proc"
					mount --bind /sys "${WORKDIR}/archlinux-bootstrap/sys"
					echo 'Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch' > \
						"${WORKDIR}/archlinux-bootstrap/etc/pacman.d/mirrorlist"
					chroot "${WORKDIR}/archlinux-bootstrap" pacman-key --init
					chroot "${WORKDIR}/archlinux-bootstrap" pacman-key --populate
				EOF
				bootstrap_ready=true
			fi

			sudo mkdir -p "${WORKDIR}/archlinux-bootstrap/archlinux-${arch}"

			if [ "$arch" = "i686" ]; then
				# Configure bootstrap for i686 only when needed
				cat <<-EOF | sudo unshare -mpf bash -e -
					sed -i 's|Architecture = auto|Architecture = i686|' \
						"${WORKDIR}/archlinux-bootstrap/etc/pacman.conf"
					sed -i 's|Required DatabaseOptional|Never|' \
						"${WORKDIR}/archlinux-bootstrap/etc/pacman.conf"
					echo 'Server = https://de.mirror.archlinux32.org/\$arch/\$repo' > \
						"${WORKDIR}/archlinux-bootstrap/etc/pacman.d/mirrorlist"
				EOF
			fi

			# Build specific architecture
			cat <<-EOF | sudo unshare -mpf bash -e -
				mount --bind "${WORKDIR}/archlinux-bootstrap/" "${WORKDIR}/archlinux-bootstrap/"
				mount --bind /dev "${WORKDIR}/archlinux-bootstrap/dev"
				mount --bind /proc "${WORKDIR}/archlinux-bootstrap/proc"
				mount --bind /sys "${WORKDIR}/archlinux-bootstrap/sys"
				chroot "${WORKDIR}/archlinux-bootstrap" pacstrap -K /archlinux-${arch} base sudo
			EOF

			sudo mv "${WORKDIR}/archlinux-bootstrap/archlinux-${arch}" "${WORKDIR}/archlinux-$(translate_arch "$arch")"

			# Post-configuration
			sudo sed -i 's/#DisableSandbox/DisableSandbox/' "${WORKDIR}/archlinux-$(translate_arch "$arch")/etc/pacman.conf"
			;;
		esac

		# Keep the pkg directory intact, only remove cached archives
		sudo rm -rf "${WORKDIR:?}/archlinux-$(translate_arch "$arch")"/var/cache/pacman/pkg/*

		archive_rootfs "${ROOTFS_DIR}/archlinux-$(translate_arch "$arch")-${dist_version}.tar.xz" \
			"archlinux-$(translate_arch "$arch")"
	done

	# Cleanup bootstrap directory if it was created
	if [ "$bootstrap_ready" = "true" ]; then
		sudo rm -rf "${WORKDIR}/archlinux-bootstrap"
	fi
}
