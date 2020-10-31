#!/bin/bash
#
# rlx-lsinitramfs
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

INITRAMFS_FILE=${1:-"/boot/initramfs.img"}

[[ -e "$INITRAMFS_FILE" ]] || {
    echo "[Error]: $INITRAMFS_FILE not exist"
    exit 1
}

gzip -dc "$INITRAMFS_FILE" | bsdcpio -it