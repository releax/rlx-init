#!/bin/sh

set -e

DESTDIR=${DESTDIR:-"/"}
PREFIX=${PREFIX:-"/usr/"}
BINDIR=${BINDIR:-"$PREFIX/sbin/"}
DATADIR=${DATADIR:-"$PREFIX/share/"}

install -vDm755 bin/rlx-init.sh ${DESTDIR}${BINDIR}/rlx-init
install -vDm755 bin/rlx-lsinit.sh ${DESTDIR}${BINDIR}/rlx-lsinit

install -vDm644 src/init.sh ${DESTDIR}$DATADIR/rlx-init/init.in