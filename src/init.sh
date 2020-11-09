#!/bin/bash
#
# init.in
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

export PATH=/bin:/sbin

RESET='\033[0m'
BLACK='\033[1;30m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
BBOLD='\033[1m'

# rescue_shell 'fail message'
# drop the boot process into rescue mode for debug
rescue_shell() {

    echo -e "${RED}$1${RESET}\n${YELLOW}Dropping to ${GREEN}resuce${YELLO}shell${RESET}"
    dmesg | tail -n 5

    [[ -f /keymap ]] && loadkmap < /keymap
    exec setsid cttyhack /bin/sh
}

# debug 'message'
# print debug messages if enable
debug() {
    [[ -z "$DEBUG" ]] && return
    echo -e "${GREEN}debug${RESET}:${BBOLD}$@${RESET}"
}

# mount_filesystem
# mount pseudo filesystems devtmpfs, sysfs, proc
mount_filesystem() {
    mount -t proc     none /proc || rescue_shell "failed to mount /proc"
    mount -t sysfs    none /sys  || rescue_shell "failed to mount /sys"
    mount -t devtmpfs none /dev  || rescue_shell "failed to mount /dev"
    mount -t tmpfs    none /run  || rescue_shell "failed to mount /run"
}

# load_modules
# load required modules if specified in cmdline or if booting from iso
load_modules() {

    # load modules required for booting from squashfs image (cdrom)
    [[ -n "$squa" ]] && modules="$modules cdrom sr_mod isofs overlay"

    for m in $modules ; do
        modprobe $m || rescue_shell "failed to load $m module"
    done
    
}

# search_roots
# search roots 
search_roots() {
    oldroot=${root}

    root=$(findfs ${root})
    [[ -z "$root" ]] && rescue_shell "failed to find roots from '${oldroot}'"

    # TODO
    # find root device from every block node /dev/? (check for /usr/etc/rlx-release)

}

# prepare_cdrom
# prepare roots from cdrom while booting live system or cdrom
prepare_cdrom() {
    mkdir -p /run/{initrd,iso}
    # mount iso device (sr0) -> /run/iso
    mount -o ro "${root}" /run/iso || rescue_shell "failed to mount iso ${YELLOW}(squa enabled)${RESET}"

    # mount squa image -> /run/initrd/overlay/squa
    [[ -d /run/initrd/overlay/squa ]] || mkdir -p /run/initrd/overlay/squa
    [[ -e "/run/iso/${squa}" ]] || rescue_shell "'${squa}' not exist in iso"

    mount -t squashfs "/run/iso/${squa}" /run/initrd/overlay/squa || rescue_shell "failed to mount squa ${squa} to /run/initrd/overlay/squa"

    mkdir -p /run/initrd/overlay/{upper,work}
    
    rootpoint=/mnt/root
    mkdir -p $rootpoint
    mount -t overlay -o lowerdir=/run/initrd/overlay/squa,upperdir=/run/initrd/overlay/upper,workdir=/run/initrd/overlay/work none $rootpoint
}

# mount_root
# mount root device to /mnt/root
mount_root() {
    [[ -d "${rootpoint}" ]] || mkdir -p "${rootpoint}"
    mount -o "${ro}" "${root}" "${rootpoint}" || rescue_shell "failed to mount roots ${root} to /mnt/root"
}


# check_resume
# check if resume from hibernation
check_resume() {
    if [ -n "${resume}" ] ; then
        debug "resuming from ${resume}"
        printf '%u:%u\n' $(stat -L -c '0x%t 0x%T' "${resume}") > /sys/power/resume || \
            rescue_shell "activating resume failed"
    fi
}

# parse_cmdline_args
# parse linux cmdline args from /proc/cmdline
parse_cmdline_args() {
    for p in $(cat /proc/cmdline) ; do
        case "${p}" in
            root=*)
                root="${p#*=}"
                ;;

            squa=*)
                squa="${p#*=}"
                ;;

            resume=*)
                resume="${p#*=}"
                ;;

            ro|rw)
                ro="${p}"
                ;;

            init=*)
                init="${p#*=}"
                ;;
            
            debug)
                DEBUG=1
                ;;
        esac
    done
}


function main() {

    # Default variables
    root=
    resume=
    ro='ro'
    init='/sbin/init'
    squa=
    rootpoint='/mnt/root'

    echo -e "${BOLD}welcome to ${GREEN}rlxos${RESET}"

    mount_filesystem
    parse_cmdline_args

    debug "loading modules"
    load_modules

    debug "searching roots"
    search_roots

    if [[ -z "$squa" ]] ; then
        debug "mounting roots"
        mount_root
    else
        debug "preparing and mounting iso"
        prepare_cdrom
    fi

    debug "checking resume"
    check_resume

    exec switch_root "${rootpoint}" "${init}" || rescue_shell "failed to switch roots"
}


main
