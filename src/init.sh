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


rescue_shell() {
    printf '\033[1;31m'
    printf '$1 Dropping to rescue shell'
    printf '\033[00m\n'

    [[ -f /keymap ]] && loadkmap < /keymap
    exec setsid cttyhack /bin/sh
}

mount -t proc     none /proc || rescue_shell "mount /proc failed"
mount -t sysfs    none /sys  || rescue_shell "mount /proc failed"
mount -t devtmpfs none /dev  || rescue_shell "mount /proc failed"

root=
resume=
ro='ro'
init='/sbin/init'
squa=

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

    esac
done

if [[ -z $squa ]] ; then
    root="$(findfs ${root})"
    mount -o "${ro}" "${root}" /mnt/root || rescue_shell "mount ${root} failed"
else
    mount -o $squa /mnt/root || rescue_shell "mount ${squa} failed"
fi

if [ -n "${resume}" ] ; then
    printf '%u:%u\n' $(stat -L -c '0x%t 0x%T' "${resume}") > /sys/power/resume || \
        rescue_shell "Activating resume failed"
fi

umount /proc /sys /dev

exec switch_root /mnt/root "${init}"