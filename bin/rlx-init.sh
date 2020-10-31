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

INITRD_DIR=$(mktemp -d /tmp/rlx-init.XXXXXXXXXX)
INIT_IN=${INIT_IN:-'/usr/share/rlx-init/init.in'}

export LC_ALL=C

debug() {
    [[ -z $DEBUG ]] && return

    echo -ne "\033[1;32m"
    echo $@ >&2
    echo -ne "\033[00m"
}

warn() {
    echo -ne "\033[1;33m"
    echo $@ >&2
    echo -ne "\033[00m"
}

error() {
    echo -ne "\033[1;31m"
    echo $@ >&2
    echo -ne "\033[00m"
    clean
    exit 1
}

clean() {
    rm -r "${INITRD_DIR}"
}

copy() {
    debug "copy $@"

	src=$1
	dst=$2
	if [ -z "${dst}" ]; then
		# $dst is not given, use the base directory of $src
		dst="$(dirname -- "$1")/"
	fi

	# check if the file will be copied into the initrd root
	# realpath will remove trailing / that are needed later on...
	add_slash=false
	if [ "${dst%/}" != "${dst}" ]; then
		# $dst has a trailing /
		add_slash=true
	fi
	dst="$(realpath --canonicalize-missing -- ${INITRD_DIR}/${dst})"
	${add_slash} && dst="${dst}/"

	# check if $src exists
	if [ ! -e "${src}" ]; then
		warn "Cannot copy '${src}'. File not found. Skipping."
		return
	fi
	# check if the destination is really inside ${INITRD_DIR}
	if [ "${dst}" = "${dst##${INITRD_DIR}}" ]; then
        warn "${dst}"
		warn "Invalid destination $2 for $1. Skipping."
		return
	fi

	# check if the destination is a file or a directory and 
	# if it already exists
	if [ -e "${dst}" ]; then
		# $dst exists, but that's ok if it is a directory
		if [ -d "${dst}" ]; then
			# $dst is an existing directory
			dst_dir="${dst}"
			if [ -e "${dst_dir}/$(basename -- "${src}")" ]; then
				# the file exists in the destination directory, silently skip it
				debug "Target file exists, skiping."
				return
			fi
		else
			# $dst exists, but it's not a directory, silently skip it
			debug "Target file exists, skiping."
			return
		fi
	else
		if [ "${dst%/}" != "${dst}" ]; then
			# $dst ends in a /, so it must be a directory
			dst_dir="$dst"
		else
			# probably a file
			dst_dir="$(dirname -- "${dst}")"
		fi
		# make sure that the destination directory exists
		mkdir -p -- "${dst_dir}"
	fi

	# copy the file
	debug "cp -a ${src} ${dst}"
	cp -a "${src}" "${dst}" || error "Error: Could not copy ${src}"
	if [ -h "${src}" ]; then
		# $src is a symlink, follow it
		link_target="$(readlink -- "${src}")"
		if [ "${link_target#/}" = "${link_target}" ]; then
			# relative link, make it absolute
			link_target="$(dirname -- "${src}")/${link_target}"
		fi
		# get the canonical path, i.e. without any ../ and such stuff
		link_target="$(realpath --no-symlink -- "${link_target}")"
		debug "Following symlink to $link_target"
		copy "${link_target}"
	elif [ -f "${src}" ]; then
		mime_type="$(file --brief --mime-type -- "${src}")"
		if [ "${mime_type}" = "application/x-sharedlib" ] || \
		   [ "${mime_type}" = "application/x-executable" ] || \
		   [ "${mime_type}" = "application/x-pie-executable" ]; then
			# $src may be dynamically linked, copy the dependencies
			# lddtree -l prints $src as the first line, skip it
			lddtree -l "${src}" | tail -n +2 | while read file; do
				debug "Recursing to dependency $file"
				copy "${file}"
			done
		fi
	fi
}


# if grep -q /boot /proc/mounts ; then
#     umount_boot=false
# else
#     mount /boot || error "Error: failed to mount /boot"
#     umount_boot=true
# fi

mkdir -p -- "${INITRD_DIR}/"{bin,dev,etc,lib,mnt/root,proc,sbin,sys}
copy /dev/console /dev/
copy /dev/null /dev/

if [[ ! -e /bin/busybox ]] ; then
    wget https://www.busybox.net/downloads/binaries/1.31.0-i686-uclibc/busybox
    chmod 755 busybox
    copy ./busybox bin/
    rm busybox
else
    copy /bin/busybox bin/
fi

for applet in $(${INITRD_DIR}/bin/busybox --list | grep -Fxv busybox) ; do
    if [[ -e "/sbin/${applet}" ]] ; then
        ln -s /bin/busybox "${INITRD_DIR}/sbin/${applet}"
    else
        ln -s /bin/busybox "${INITRD_DIR}/bin/${applet}"
    fi
done

install -vm755 "${INIT_IN}" "${INITRD_DIR}/init"

cd "${INITRD_DIR}"

find . -print0 | cpio --null -ov --format=newc | gzip -9 > /boot/initrd

chmod 400 /boot/initrd

clean