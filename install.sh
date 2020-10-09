#!/bin/sh

set -e

DESTDIR=${DESTDIR:-"/"}
PREFIX=${PREFIX:-"/usr/"}
BINDIR=${BINDIR:-"$PREFIX/sbin/"}
DATADIR=${DATADIR:-"$PREFIX/share/"}

install -vDm755 bin/rlx-initramfs.sh ${DESTDIR}${BINDIR}/rlx-initramfs
install -vDm755 bin/rlx-lsinitramfs.sh ${DESTDIR}${BINDIR}/rlx-lsinitramfs
install -vDm755 bin/lddtree.sh ${DESTDIR}${BINDIR}/lddtree

install -vDm644 src/init.in.sh ${DESTDIR}$DATADIR/rlx-initramfs/init.in