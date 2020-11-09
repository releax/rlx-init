#!/bin/bash
#
# rlx-init
# Copyright (C) 2020 rlxos

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Based on https://wiki.gentoo.org/wiki/Custom_Initramfs/Examples
#

ROOT=
CRYPT_ROOT=
RESUME=

BINARIES="sh bash cat cp dd killall ls mkdir mknod mount \
	 umount sed sleep ln rm uname readlink basename \
	 modprobe kmod insmod lsmod blkid \
	 blkid dmesg findfs tail head \
	 switch_root mdadm mdmon losetup touch install"

INITRD_DIR=$(mktemp -d /tmp/rlx-init.XXXXXXXXXX)
INIT_IN=${INIT_IN:-'/usr/share/rlx-init/init.in'}
KERNEL=${KERNEL:-$(uname -r)}
unsorted=$(mktemp /tmp/unsorted.XXXXXXXXXX)
AOUT="/boot/initrd"

export LC_ALL=C

debug() {
    [[ -z $DEBUG ]] && return
    echo -e "\033[1;32m$@\033[00m"
}

warn() {
    echo -e "\033[1;33m$@\033[00m"
}

error() {
    echo -e "\033[1;31m$@\033[00m"
    cleanup
    exit 1
}

cleanup() {
    rm -r "${INITRD_DIR}"
}

# copy src dst mode
#    | src
#    | src dst
# copy src file to dst destination with mode
copy() {
    debug "copy $@"

	src=$1
	dst=$2

	if [[ "${src:0:1}" != "/" ]] ; then
		src="/$src"
	fi

	if [ -z "${dst}" ]; then
		dst=${src/\//}
	fi

	if [[ ! -e "${src}" ]] ; then
		error "file not found: $src"
		return
	fi

	mode=${3:-$(stat -c %a "${src}")}
	[[ -z "$mode" ]] && {
		warn "failed to get file mode: $src"
		return
	}

	install -Dm${mode} $src "${INITRD_DIR}/$dst"

}


# install_binary bin
# install binary into initrd
install_binary() {
	ldd $1 | sed 's/\t//' | cut -d ' ' -f1 >> $unsorted
	copy $1
}


# install_libraries
# install libraries required by binaries installed from $(install_binary)
install_libraries() {
	sort $unsorted | uniq | while read library ; do
		if [[ "$library" == linux-vdso.so.1 ]] ||
		   [[ "$library" == linux-gate.so.1 ]] ; then

		   continue
		fi

		[[ $library =~ "/lib/" ]] || library="/lib/$library"
		copy $library lib/
	done
}


# parse_cmdline_args $@
# parse arguments
parse_args() {
    for p in $@ ; do
        case "${p}" in
            -k=* | --kernel=*)
				KERNEL=${p#*=}
				;;

			-i=* | --init=*)
				INIT_IN=${p#*=}
				;;

			-iso)
				ISO=1
				;;

			-o=* | --out=*)
				AOUT=${p#*=}
				;;
        esac
    done
}


# prepare_structure 
# prepare required dirs, files and nodes
prepare_structure() {
	mkdir -p -- "${INITRD_DIR}/"{bin,dev,etc,lib,mnt/root,proc,sbin,sys,run}
	copy /dev/console /dev/
	copy /dev/null /dev/

	for i in $BINARIES ; do
		[[ -x /sbin/$i ]] && loc=/sbin/$i || loc=/bin/$i
		install_binary $loc
	done

	# installing init
	install -m755 "${INIT_IN}" "${INITRD_DIR}/init"
}


# install_udev
# install udev daemon for dynamic module loading
# required when booting from non native system (iso, live booting)
install_udev() {
	install_binary udevd
	install_binary udevadm

	for i in ata_id scsi_id cdrom_id  mtd_probe v4l_id ; do
		install_binary /lib/udev/${i}
	done

	for i in /lib/udev/rules.d/*.rules ; do
		copy $i
	done
}


# install_modules
# install extra kernel modules
install_modules() {

	mkdir -p $INITRD_DIR/lib/modules/$KERNEL/

	copy /lib/modules/$KERNEL/kernel/fs/isofs/isofs.ko.xz
	copy /lib/modules/$KERNEL/kernel/drivers/cdrom/cdrom.ko.xz
	copy /lib/modules/$KERNEL/kernel/drivers/scsi/sr_mod.ko.xz
	copy /lib/modules/$KERNEL/kernel/fs/overlayfs/overlay.ko.xz

	for i in /lib/modules/$KERNEL/modules.* ; do
		copy $i
	done
}

# compress_initrd
# install required libraries
# compress initrd
# change mode to 400
compress_initrd() {

	install_libraries

	(cd "${INITRD_DIR}"; find . | LANG=C bsdcpio -o -H newc --quiet | gzip -9) > "${AOUT}"

	chmod 400 "${AOUT}"
}


function main {

	parse_args $@

	prepare_structure

	# prepare initrd from iso
	if [[ -n "$ISO" ]] ; then
		install_udev
		install_modules
	fi

	compress_initrd

	cleanup
}


main $@