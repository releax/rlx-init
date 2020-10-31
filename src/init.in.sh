#!/bin/sh
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



GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

debug_mesg() {
    [[ $DEBUG ]] && echo -e "${BLUE}DEBUG${NC}:${BOLD}$@${NC}"
}

function RescueShell {
    printf '\e[1;31m'
    printf $1
    printf '\e[0m\n'

    [[ -f /keymap ]] && loadkmap < /keymap
    exec setsid cttyhack /bin/sh
}

# Initialization
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

root=""
resume=""
ro_rw='ro'
init="/sbin/init"
delay=0

for p in $(cat /proc/cmdline); do
    case "${p}" in
        crypt_root=*)
            crypt_root="${p#*=}"
            ;;

        root=*)
            root="${p#*=}"
            ;;

        resume=*)
            resume="${p#*=}"
            ;;

        ro|rw)
            ro_rw="${p}"
            ;;

        init=*)
            init="${p#*=}"
            ;;

        debug)
            DEBUG=1
            ;;

        modules=*)
            modules="${p#*=}"
            ;;

        squa=*)
            squa="${p#*=}"
            ;;

        delay=*)
            delay="${p#*=}"
            ;;
    esac
done

if [[ -n "${crypt_root}" ]] ; then

    debug_mesg "Decrypting ${crypt_root}"
    # Decrypt
    crypt_root="$(findfs "${crypt_root}")"
    cryptsetup open "${crypt_root}" lvm --type luks --key-file /crypto_key.bin ||   \
        cryptsetup open "${crypt_root}" lvm --type luks

    debug_mesg "Activating lvm devices"
    # Activate lvm
    lvm vgscan --mknodes
    lvm vgchange --sysinit -a ly
    lvm vgscan --mknodes
fi

if [[ -n "${modules}" ]] ; then
    for i in ${modules} ; then
        debug_mesg "loading modules - ${i}"
        modprobe $i
    done
fi

debug_mesg "delay $delay secs"
sleep $delay

if [[ -n "${squa}" ]] ; then
    debug_mesg "Using squash for boot"
    debug_mesg "Mounting squash ${squa}"

    mount -a $squa /mnt/root

else
    root="$(findfs "${root}")"

    debug_mesg "Mounting $root roots"
    mount -o "${ro_rw}" "${root}" /mnt/root
fi

if [[ -n "${resume}" ]] ; then
    debug_mesg "Resuming state from ${resume}"
    printf '%u:%u\n' $(stat -L -c '0x%t 0x%T' "${resume}") > /sys/power/resume
fi


umount /proc
umount /sys
umount /dev

debug_mesg "Switching root"
exec switch_root /mnt/root $init
