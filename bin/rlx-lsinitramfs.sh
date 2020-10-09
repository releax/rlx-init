#!/bin/bash

INITRAMFS_FILE=${1:-"/boot/initramfs.img"}

[[ -e "$INITRAMFS_FILE" ]] || {
    echo "[Error]: $INITRAMFS_FILE not exist"
    exit 1
}

gzip -dc "$INITRAMFS_FILE" | bsdcpio -it