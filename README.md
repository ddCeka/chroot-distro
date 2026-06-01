
## Note

#### this is a personal fork for personal use, as well as backup from before the original source changed into python package.

> [!TIP]
> you may want to find the [original](https://github.com/sabamdarif/chroot-distro) source instead.

<div align="center">

# Chroot Distro

#### Install Linux distributions on Android devices using chroot

</div>

## Prerequisites

- **Back up important files before use**
- **Rooted Android Device**
- **BusyBox**: [osm0sis/android-busybox-ndk](https://github.com/osm0sis/android-busybox-ndk) (**Recommended:** v1.36.1)

> [!TIP]
> KernelSU users do not need to flash busybox as it has built-in busybox support.

---

## Supported Distributions

|                                                                                                                         |                                                                                                                      |                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------: |
| ![Alpine Linux](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white) |  ![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)   |  ![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)   |
|          ![Fedora](https://img.shields.io/badge/Fedora-51A2DA?style=for-the-badge&logo=fedora&logoColor=white)          |  ![Kali Linux](https://img.shields.io/badge/Kali_Linux-557C94?style=for-the-badge&logo=kali-linux&logoColor=white)   | ![Manjaro](https://img.shields.io/badge/Manjaro-35BF5C?style=for-the-badge&logo=manjaro&logoColor=white) |
|       ![OpenSUSE](https://img.shields.io/badge/OpenSUSE-73BA25?style=for-the-badge&logo=opensuse&logoColor=white)       | ![Rocky Linux](https://img.shields.io/badge/Rocky_Linux-10B981?style=for-the-badge&logo=rocky-linux&logoColor=white) |  ![Trisquel](https://img.shields.io/badge/Trisquel-0D597F?style=for-the-badge&logo=gnu&logoColor=white)  |
|          ![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)          |  ![Void Linux](https://img.shields.io/badge/Void_Linux-478061?style=for-the-badge&logo=void-linux&logoColor=white)   |                                                                                                          |

---

## Quick Start

```bash

# List available distributions
chroot-distro list

# Install a distribution
chroot-distro install debian

# Login to the distribution
chroot-distro login debian
```

---

## Command Reference

| Command        | Aliases                     | Description                    |
| -------------- | --------------------------- | ------------------------------ |
| `help`         | `--help`, `-h`, `he`, `hel` | Display help information       |
| `version`      | `--version`, `-v`           | Show version information       |
| `list`         | `li`, `ls`                  | List available distributions   |
| `list-running` |                             | List currently running distros |
| `install`      | `i`, `in`, `ins`, `add`     | Install a distribution         |
| `login`        | `sh`                        | Enter distribution shell       |
| `remove`       | `rm`                        | Remove a distribution          |
| `unmount`      | `umount`, `um`              | Unmount distribution           |
| `clear-cache`  | `clear`, `cl`               | Clear downloaded files         |

---

## Commands

### `help`

Display general help or command-specific help information:

```bash
chroot-distro help
chroot-distro <command> --help
```

### `list`

List all available distributions with their aliases, installation status, and additional information:

```bash
chroot-distro list
```

### `list-running`

List currently mounted checking for active mount points:

```bash
chroot-distro list-running
```

### `install <distro>`

Install a supported distribution:

```bash
chroot-distro install debian
```

#### Available Options

- `--skip-useradd` – Skip the user creation prompt during installation

#### Environment Variables

- `SKIP_USERADD=1` – Same as `--skip-useradd` flag

#### User Creation

During installation, you will be prompted to create a normal user account. The created user:

- Gets the **same UID as Termux**, to enabling access to Termux files (e.g., with `--termux-home`)

To skip this prompt entirely:

```bash
chroot-distro install debian --skip-useradd
```

or

```bash
SKIP_USERADD=1 chroot-distro install debian
```

To automate user creation without interactive prompts:

```bash
chroot-distro install debian --adduser username password
```

### `login <distro>`

Enter a shell session inside the installed distribution:

```bash
chroot-distro login debian
```

#### Available Options

- `--user <username>` – Login as a specified user (user must exist in chroot environment)
- `--isolated` - Run the specified distro in an isolated chroot environment
- `--shared-tmp` - Share Termux tmp directory (no compatible with `--isolated`)
- `--termux-home` – Mount Termux home directory inside chroot (no compatible with `--isolated`)
- `--bind <host_path>:<chroot_path>` – Bind mount a path from host to chroot (no compatible with `--isolated`)
- `--work-dir <path>` – Set custom working directory (default: user's home directory)

#### Execute Commands

Run commands directly inside the chroot environment:

```bash
chroot-distro login debian -- /bin/sh -c 'apt update'
```

Use `--` to separate chroot-distro options from the target command.

### `unmount <distro>`

Unmount all mount points associated with a distribution:

```bash
chroot-distro unmount debian
```

#### Options

- `--help` – Display help for this command

#### Examples

```bash
chroot-distro unmount debian
```

### `remove <distro>`

Permanently remove an installed distribution.

> [!WARNING]
> This operation is irreversible and does not prompt for confirmation.
> It may destroy your /data/ rom files. DWYOR.

```bash
chroot-distro remove fedora
```

### `clear-cache`

Remove all downloaded rootfs archives to free up storage space:

```bash
chroot-distro clear-cache
```

---

## Service Management

Chroot Distro includes a lightweight service manager called `serviced` it can start a systemd process without systemd

### Configuration

The service manager behavior can be configured via the `settings.conf` file located at:

```
/data/local/chroot-distro/data/settings.conf
```

> [!TIP]
> This file can be easily configured using the WebUI.

### Options

| Option                  | Description                                                                 |
| ----------------------- | --------------------------------------------------------------------------- |
| `SERVICED`              | Set to `true` to enable the service manager.                                |
| `SERVICED_VERBOSE_MODE` | Set to `true` to enable verbose logging for debugging service start issues. |

### Usage

When `SERVICED` is enabled, `chroot-distro` will automatically start the built-in `serviced` manager when you login. You can then use it to manage services:

```bash
# Start a service
serviced start <service>

# Start all enabled services
serviced start

# Enable a service to start on boot
serviced enable <service>

# Disable a service
serviced disable <service>

# Check status
serviced status <service>

# List all services
serviced list
```

---

## Termux Integration

To simplify usage from Termux, create a wrapper script:

1. Open Termux and run:

```bash
nano $PREFIX/bin/chroot-distro
```

2. Paste the following content:

```bash
#!/data/data/com.termux/files/usr/bin/env sh

args=""
for arg in "$@"; do
    escaped_arg=$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")
    args="$args '$escaped_arg'"
done

su -c "/system/bin/chroot-distro $args"
```

3. Make the script executable:

```bash
chmod +x $PREFIX/bin/chroot-distro
```

- You can now use chroot-distro directly from Termux without switching to root user manually.

---

## License

This project is licensed under the **[GNU General Public License v3.0](LICENSE)**

```
Copyright (C) 2026 ddCeka

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

---

## Acknowledgments:

Special thanks to:

- [sabamdarif/chroot-distro](https://github.com/sabamdarif/chroot-distro)
- [proot-distro](https://github.com/termux/proot-distro)
- [Magisk-Modules-Alt-Repo/chroot-distro](https://github.com/Magisk-Modules-Alt-Repo/chroot-distro)
- [ravindu644/Ubuntu-Chroot](https://github.com/ravindu644/Ubuntu-Chroot)
- [gdraheim/docker-systemctl-replacement](https://github.com/gdraheim/docker-systemctl-replacement)
