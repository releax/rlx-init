#!/bin/bash
#
# Based on https://wiki.gentoo.org/wiki/Custom_Initramfs/Examples
#

INITRAMFS_DIR='/tmp/rlx-initramfs'
INIT_FILE='/usr/share/rlx-initramfs/init.in'
OUT_FILE='/boot/initramfs.img'
KERNEL_VERSION=$(uname -r)

export LC_ALL=C

REQUIRED_BINS="sh bash cat cp dd killall ls mkdir mknod mount
umount sed sleep ln rm uname readlink basename udevd udevadm
modprobe kmod insmod lsmod blkid switch_root mdadm mdmom losetup
touch install lvm cryptsetup findfs
lvchange lvrename lvextend lvcreate lvscan"

UDEV_RULES="50-udev-default 60-persistent-storage 64-btrfs 80-drivers 60-cdrom"
UDEV_LIBS="ata_id scsi_id cdrom_id"
KERNEL_MODULES="cdrom loop overlay"

function Copy {
    #echo "[Info]: copying $@"

    local src dst
    src="$1"
    dst="$2"

    [[ -z "${dst}" ]] && dst="$(dirname -- "$1")/"

    add_slash=false
    [[ "${dst%/}" != "${dst}" ]] && add_slash=true

    dst="$(realpath --canonicalize-missing -- ${INITRAMFS_DIR}/${dst})"
    ${add_slash} && dst="${dst}/"

    [[ ! -e "${src}" ]] && {
        echo "[Error]: can't copy ${src}, not found"
        return
    }

    [[ "${dst}" = "${dst##${INITRAMFS_DIR}}" ]] && {
        echo "[Error]: invalid destination $2 in $1. Skipping"
        return
    }

    if [[ -e "${dst}" ]] ; then
        if [[ -d "${dst}" ]] ; then
            dst_dir="${dst}"
            if [[ -e "${dst_dir}/$(basename -- "${src}")" ]] ; then
                #echo "[Error]: ${src} already exist, skipping"
                return
            fi
        else
            #echo "[Error]: ${src} file exist, skipping"
            return
        fi
    else
        if [[ "${dst%/}" != "${dst}" ]] ; then
            dst_dir="$dst"
        else
            dst_dir="$(dirname -- "${dst}")"
        fi

        mkdir -p -- "${dst_dir}"
    fi

    #echo "[Info]: cp -a ${src} ${dst}"
    cp -a "${src}" "${dst}" || echo "[Error]: failed to copy ${src}"

    if [[ -h "${src}" ]] ; then
        link_target="$(readlink -- "${src}")"
        if [[ "${link_target#/}" = "${link_target}" ]] ; then
            link_target="$(dirname -- "${src}")/${link_target}"
        fi

        link_target="$(realpath --no-symlink -- "${link_target}")"
        #echo "[Info]: Following symlink ${link_target}"
        Copy "${link_target}"
    elif [[ -f "${src}" ]] ; then
        mime_type="$(file --brief --mime-type -- "${src}")"
        if [[ "${mime_type}" = "application/x-sharedlib" ]]  || \
		   [[ "${mime_type}" = "application/x-executable" ]] || \
		   [[ "${mime_type}" = "application/x-pie-executable" ]]; then
           
           lddtree -l "${src}" | tail -n +2 | while read line ; do
                #echo "[Info]: recursing to dependency $line"
                Copy "${line}"
            done
        fi
    fi
}

function InstallModule {
    local mod_name mod_path

    if modinfo -k $KERNEL_VERSION "$1" &>/dev/null ; then
        mod_name=$(modinfo -k $KERNEL_VERSION -F name "$1")
        mod_path=$(modinfo -k $KERNEL_VERSION -F filename "$1")
    else
        echo "[Error]: Kernel module '$1' missing"
    fi

    [[ -f "${INITRAMFS_DIR}/${mod_path}" ]] && return

    Copy "$mod_path" "$(dirname ${mod_path})"
    
    modinfo -F firmware -k "${KERNEL_VERSION}" "${mod_name}" | while read -r line ; do
        if [[ ! -f "/lib/firmware/$line" ]] ; then
            echo "[Info]: Module firmware '$line' missing" 
        else
            Copy "/lib/firmware/$line" "/lib/firmware/$line"
        fi
    done

    modinfo -F depends -k "${KERNEL_VERSION}" "${mod_name}" | while IFS=',' read -r line ; do
        for l in ${line[@]} ; do
            InstallModule $l
        done
    done
}

function SetupStructure {
    mkdir -pv "${INITRAMFS_DIR}/"{dev,lib,run,sys,proc,usr,bin}
    mkdir -pv "${INITRAMFS_DIR}"/lib/{firmware,modules/$KERNEL_VERSION}
    mkdir -pv "${INITRAMFS_DIR}"/etc/{modprobe.d,udev/rules.d}
    touch "${INITRAMFS_DIR}"/etc/modprobe.d/modprobe.conf
    for i in lib bin sbin ; do
        ln -s ../$i ${INITRAMFS_DIR}/usr/$i
    done

    ln -s bin ${INITRAMFS_DIR}/sbin

    mknod -m640 ${INITRAMFS_DIR}/dev/console c 5 1
    mknod -m664 ${INITRAMFS_DIR}/dev/null    c 1 3
}

function Main {
    
    for i in $@ ; do
        case "$i" in
            --kernel=*)
                KERNEL_VERSION="${i#*=}"
                ;;

            --out=*)
                OUT_FILE="${i#*=}"
                ;;
            
            --init=*)
                INIT_FILE="${i#*=}"
                ;;

            --binary=*)
                REQUIRED_BINS="$REQUIRED_BINS ${i#*=}"
                ;;
            
            --udev-rules=*)
                UDEV_RULES="${UDEV_RULES} ${i#*=}"
                ;;

            --udev-libs=*)
                UDEV_LIBS="${UDEV_LIBS} ${i#*=}"
                ;;

            --modules=*)
                KERNEL_MODULES="${KERNEL_MODULES} ${i#*=}"
                ;;

        esac
    done

    LIBSTR="${INITRAMFS_DIR}/lib.sorted"

    [[ ! -d "/lib/modules/$KERNEL_VERSION" ]] && {
        echo "[Error]: No modules directory found for $KERNEL_VERSION"
        exit 1
    }

    echo "[Info]: Creating $OUT_FILE..."
    [[ -d "${INITRAMFS_DIR}" ]] && rm -r "${INITRAMFS_DIR}"
    mkdir -p "${INITRAMFS_DIR}"

    SetupStructure

    [[ -f /etc/udev/udev.conf ]] && Copy /etc/udev/udev.conf

    for i in $UDEV_RULES
    do
        Copy /lib/udev/rules.d/$i.rules
    done

    for i in $UDEV_LIBS ; do
        Copy /lib/udev/$i
    done
${KERNEL_MODULES} ${i#*=}

    [[ -f /etc/mdadm.conf ]] && Copy /etc/mdadm.conf

    install -m0755 $INIT_FILE ${INITRAMFS_DIR}/init

    for b in $REQUIRED_BINS ; do
        loc=$(which $b) || echo "[Error]: Failed to add $b (not exist)"
        ldd $(echo $loc) | sed 's/\t//' | cut -d ' ' -f1 >> $LIBSTR
        Copy $loc /bin
    done
        
    [[ -e /etc/lvm ]] && Copy /etc/lvm

    sort $LIBSTR | uniq | while read library ; do
        if [[ "$library" == "linux-vdso.so.1" ]] ||
           [[ "$library" == "linux-gate.so.1" ]]
        then
            continue
        fi

        Copy $library /lib/
    done

    for i in $(find                                                                 \
        /lib/modules/${KERNEL_VERSION}/kernel/{crypto,fs,lib}                       \
        /lib/modules/${KERNEL_VERSION}/kernel/drivers/{block,ata,md,firewire}       \
        /lib/modules/${KERNEL_VERSION}/kernel/drivers/{scsi,message,pcmcia,virtio}  \
        /lib/modules/${KERNEL_VERSION}/kernel/drivers/usb/{host,storage}            \
        -type f)
    do
        mod=$(basename $i | sed 's/.ko.xz//g')
        InstallModule "$mod"
    done

    for i in $KERNEL_MODULES ; do
        InstallModule $i
    done

    cp /lib/modules/${KERNEL_VERSION}/modules.{builtin,order}   \
        "${INITRAMFS_DIR}/lib/modules/${KERNEL_VERSION}/"
    
    depmod -b "${INITRAMFS_DIR}" "$KERNEL_VERSION"

    Copy /boot/uk.bkeymap /keymap

    Copy /sbin/cryptsetup /sbin/
    Copy /boot/crypto_key.bin /crypto_key.bin

    Copy /sbin/lvm.static /sbin/lvm
    Copy /sbin/lvm /sbin/lvm

    install -vDm755 $INIT_FILE "${INITRAMFS_DIR}/init"

    cd "${INITRAMFS_DIR}"

    rm ${LIBSTR}

    find . -print0 | cpio --null -ov --format=newc | gzip -9 > "$OUT_FILE"

    chmod 400 $OUT_FILE

    rm -r ${INITRAMFS_DIR} 
}

Main $@