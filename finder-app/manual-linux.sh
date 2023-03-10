#!/bin/sh
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"

if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi

if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- ...
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig CONFIG_PVPANIC=y
    # PATCH THERE
    git apply ${FINDER_APP_DIR}/dtc-lexer.patch

    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    #make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs
fi

echo "Adding the Image in outdir"
cp -a ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf rootfs
fi

mkdir rootfs
cd rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin 
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
else
    cd busybox
fi

# TODO: Make and install busybox
sudo make distclean
sudo make defconfig

# CROSS_COMPILE can't be found when using sudo. Have to write absolute path.
sudo make ARCH=$ARCH LDFLAGS="--static" CROSS_COMPILE=$CROSS_COMPILE install CONFIG_PREFIX="${OUTDIR}/rootfs"

cd "${OUTDIR}/rootfs"
echo "Library dependencies"
#${CROSS_COMPILE}readelf -a bin/busybox | grep NEEDED

# TODO: Add library dependencies to rootfs

cp -a "${SYSROOT}/lib/ld-linux-aarch64.so.1" lib
cp -a "${SYSROOT}/lib64/ld-2.31.so" lib64
cp -a "${SYSROOT}/lib64/libc-2.31.so" lib64
cp -a "${SYSROOT}/lib64/libm.so.6" lib64
cp -a "${SYSROOT}/lib64/libm-2.31.so" lib64
cp -a "${SYSROOT}/lib64/libresolv.so.2" lib64
cp -a "${SYSROOT}/lib64/libresolv-2.31.so" lib64
cp -a "${SYSROOT}/lib64/libc.so.6" lib64

# TODO: Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

# TODO: Clean and build the writer utility
make -C $FINDER_APP_DIR CROSS_COMPILE=$CROSS_COMPILE clean
make -C $FINDER_APP_DIR CROSS_COMPILE=$CROSS_COMPILE all

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -a $FINDER_APP_DIR/writer home
cp -a $FINDER_APP_DIR/finder.sh home
cp -a $FINDER_APP_DIR/finder-test.sh home
cp -a $FINDER_APP_DIR/autorun-qemu.sh home

mkdir home/conf
cp -a $FINDER_APP_DIR/conf/username.txt home/conf 

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
find . -print0 | cpio --null -ov --format=newc > ${OUTDIR}/initramfs.cpio
gzip ${OUTDIR}/initramfs.cpio


