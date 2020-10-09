#!/bin/sh

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

        
    esac
done

if [[ -n "${crypt_root}" ]] ; then
    # Decrypt
    crypt_root="$(findfs "${crypt_root}")"
    cryptsetup open "${crypt_root}" lvm --type luks --key-file /crypto_key.bin ||   \
        cryptsetup open "${crypt_root}" lvm --type luks

    # Activate lvm
    lvm vgscan --mknodes
    lvm vgchange --sysinit -a ly
    lvm vgscan --mknodes
fi

root="$(findfs "${root}")"
mount -o "${ro_rw}" "${root}" /mnt/root


if [[ -n "${resume}" ]] ; then
    printf '%u:%u\n' $(stat -L -c '0x%t 0x%T' "${resume}") > /sys/power/resume
fi


umount /proc
umount /sys
umount /dev

exec switch_root /mnt/root /sbin/init
