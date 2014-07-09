RELEASE=3.2

KERNEL_VER=2.6.32
PKGREL=130
# also include firmware of previous versrion into
# the fw package:  fwlist-2.6.32-PREV-pve
KREL=30

RHKVER=431.17.1.el6
OVZVER=042stab090.5

KERNELSRCRPM=vzkernel-${KERNEL_VER}-${OVZVER}.src.rpm

EXTRAVERSION=-${KREL}-pve
KVNAME=${KERNEL_VER}${EXTRAVERSION}
PACKAGE=pve-kernel-${KVNAME}
HDRPACKAGE=pve-headers-${KVNAME}

ARCH=amd64
GITVERSION:=$(shell cat .git/refs/heads/master)

TOP=$(shell pwd)

KERNEL_SRC=linux-2.6-${KERNEL_VER}
RHKERSRCDIR=rh-kernel-src
KERNEL_CFG=config-${KERNEL_VER}
KERNEL_CFG_ORG=config-${KERNEL_VER}-${OVZVER}.x86_64

AOEDIR=aoe6-77
AOESRC=${AOEDIR}.tar.gz

E1000EDIR=e1000e-3.0.4.1
E1000ESRC=${E1000EDIR}.tar.gz

IGBDIR=igb-5.1.2
IGBSRC=${IGBDIR}.tar.gz

IXGBEDIR=ixgbe-3.19.1
IXGBESRC=${IXGBEDIR}.tar.gz

BNX2DIR=netxtreme2-7.8.56
BNX2SRC=${BNX2DIR}.tar.gz

AACRAIDVER=1.2.1-40300
AACRAIDSRC=aacraid-linux-src-${AACRAIDVER}.tgz
AACRAIDDIR=aacraid

MEGARAID_DIR=megaraid_sas-06.602.03.00
MEGARAID_SRC=${MEGARAID_DIR}-src.tar.gz

ARECADIR=arcmsr-1.30.0X.16-20131206
ARECASRC=${ARECADIR}.zip

RR272XSRC=RR272x_1x-Linux-Src-v1.5-130325-0732.tar.gz
RR272XDIR=rr272x_1x-linux-src-v1.5

ISCSITARGETDIR=iscsitarget-1.4.20.2
ISCSITARGETSRC=${ISCSITARGETDIR}.tar.gz

DST_DEB=${PACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
HDR_DEB=${HDRPACKAGE}_${KERNEL_VER}-${PKGREL}_${ARCH}.deb
PVEPKG=proxmox-ve-${KERNEL_VER}
PVE_DEB=${PVEPKG}_${RELEASE}-${PKGREL}_all.deb

all: check_gcc ${DST_DEB} ${PVE_DEB} ${HDR_DEB}

${PVE_DEB} pve: proxmox-ve/control proxmox-ve/postinst
        rm -rf proxmox-ve/data
        mkdir -p proxmox-ve/data/DEBIAN
        mkdir -p proxmox-ve/data/usr/share/doc/${PVEPKG}/
        install -m 0644 proxmox-ve/proxmox-release\@proxmox.com.pubkey proxmox-ve/data/usr/share/doc/${PVEPKG}
        sed -e 's/@KVNAME@/${KVNAME}/' -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@RELEASE@/${RELEASE}/' -e 's/@PKGREL@/${PKGREL}/' <proxmox-ve/control >proxmox-ve/data/DEBIAN/control
        sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' <proxmox-ve/postinst >proxmox-ve/data/DEBIAN/postinst
        chmod 0755 proxmox-ve/data/DEBIAN/postinst
        echo "git clone git://git.proxmox.com/git/pve-kernel-2.6.32.git\\ngit checkout ${GITVERSION}" > proxmox-ve/data/usr/share/doc/${PVEPKG}/SOURCE
        install -m 0644 proxmox-ve/copyright proxmox-ve/data/usr/share/doc/${PVEPKG}
        install -m 0644 proxmox-ve/changelog.Debian proxmox-ve/data/usr/share/doc/${PVEPKG}
        gzip --best proxmox-ve/data/usr/share/doc/${PVEPKG}/changelog.Debian
        dpkg-deb --build proxmox-ve/data ${PVE_DEB}

check_gcc:
        gcc --version|grep "4\.4\.5" || false

${DST_DEB}: data control.in postinst.in
        mkdir -p data/DEBIAN
        sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' <control.in >data/DEBIAN/control
        sed -e 's/@@KVNAME@@/${KVNAME}/g'  <postinst.in >data/DEBIAN/postinst
        chmod 0755 data/DEBIAN/postinst
        install -D -m 644 copyright data/usr/share/doc/${PACKAGE}/copyright
        install -D -m 644 changelog.Debian data/usr/share/doc/${PACKAGE}/changelog.Debian
        echo "git clone git://git.proxmox.com/git/pve-kernel-2.6.32.git\\ngit checkout ${GITVERSION}" > data/usr/share/doc/${PACKAGE}/SOURCE
        gzip -f --best data/usr/share/doc/${PACKAGE}/changelog.Debian
        rm -f data/lib/modules/${KVNAME}/source
        rm -f data/lib/modules/${KVNAME}/build
        dpkg-deb --build data ${DST_DEB}
        lintian ${DST_DEB}

fwlist-${KVNAME} fwtest: data
        ./find-firmware.pl data/lib/modules/${KVNAME} >fwlist.tmp
        cmp fwlist.tmp fwlist-2.6.32-20-pve
        mv fwlist.tmp $@

data: .compile_mark ${KERNEL_CFG} aoe.ko e1000e.ko igb.ko ixgbe.ko bnx2.ko cnic.ko bnx2x.ko iscsi_trgt.ko aacraid.ko megaraid_sas.ko rr272x_1x.ko arcmsr.ko
        rm -rf data tmp; mkdir -p tmp/lib/modules/${KVNAME}
        mkdir tmp/boot
        install -m 644 ${KERNEL_CFG} tmp/boot/config-${KVNAME}
        install -m 644 ${KERNEL_SRC}/System.map tmp/boot/System.map-${KVNAME}
        install -m 644 ${KERNEL_SRC}/arch/x86_64/boot/bzImage tmp/boot/vmlinuz-${KVNAME}
        cd ${KERNEL_SRC}; make INSTALL_MOD_PATH=../tmp/ modules_install
        # install latest aoe driver
        install -m 644 aoe.ko tmp/lib/modules/${KVNAME}/kernel/drivers/block/aoe/aoe.ko
        # install latest ixgbe driver
        install -m 644 ixgbe.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/ixgbe/
        # install latest e1000e driver
        install -m 644 e1000e.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/e1000e/
        # install latest ibg driver
        install -m 644 igb.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/igb/
        # install bnx2 drivers
        install -m 644 bnx2.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/
        install -m 644 cnic.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/
        install -m 644 bnx2x.ko tmp/lib/modules/${KVNAME}/kernel/drivers/net/bnx2x/
        # install aacraid drivers
        install -m 644 aacraid.ko tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/aacraid/
        # install megaraid_sas driver
        install -m 644 megaraid_sas.ko tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/megaraid/
        # install Highpoint 2710 RAID driver
        install -m 644 rr272x_1x.ko -D tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/rr272x_1x/rr272x_1x.ko
        # install areca driver
        install -m 644 arcmsr.ko tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/arcmsr/
        # install iscsitarget module
        install -m 644 -D iscsi_trgt.ko tmp/lib/modules/${KVNAME}/kernel/drivers/scsi/iscsi_trgt.ko
        # remove firmware
        rm -rf tmp/lib/firmware
        # strip debug info
        find tmp/lib/modules -name \*.ko -print | while read f ; do strip --strip-debug "$$f"; done
        # finalize
        depmod -b tmp/ ${KVNAME}
        mv tmp data
        
.compile_mark: ${KERNEL_SRC}/README ${KERNEL_CFG}
        cp ${KERNEL_CFG} ${KERNEL_SRC}/.config
        cd ${KERNEL_SRC}; make oldconfig
        cd ${KERNEL_SRC}; make -j 8
        touch $@

${KERNEL_CFG}: ${KERNEL_CFG_ORG} config-${KERNEL_VER}.diff
        cp ${KERNEL_CFG_ORG} ${KERNEL_CFG}.new
        patch --no-backup ${KERNEL_CFG}.new config-${KERNEL_VER}.diff
        mv ${KERNEL_CFG}.new ${KERNEL_CFG}

${KERNEL_SRC}/README: ${KERNEL_SRC}.org/README
        rm -rf ${KERNEL_SRC}
        cp -a ${KERNEL_SRC}.org ${KERNEL_SRC}
        cd ${KERNEL_SRC}; patch -p1 <../bootsplash-3.1.9-2.6.31-rh.patch
        cd ${KERNEL_SRC}; patch -p1 <../${RHKERSRCDIR}/patch-042stab090
        cd ${KERNEL_SRC}; patch -p1 <../cpt-drop-DCACHE_NFSFS_RENAMED-for-all-NFS-dentries-on-kill.patch
        cd ${KERNEL_SRC}; patch -p1 <../do-not-use-barrier-on-ext3.patch
        cd ${KERNEL_SRC}; patch -p1 <../bridge-patch.diff
        #cd ${KERNEL_SRC}; patch -p1 <../kvm-fix-invalid-secondary-exec-controls.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0001-bridge-disable-querier.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0002-bridge-disable-querier.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0003-bridge-disable-querier.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0004-bridge-disable-querier.patch
        # this enable querier by default
        cd ${KERNEL_SRC}; patch -p1 <../0005-bridge-disable-querier.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0001-bridge-only-expire-the-mdb-entry-when-query-is-recei.patch
        #cd ${KERNEL_SRC}; patch -p1 <../0002-bridge-send-query-as-soon-as-leave-is-received.patch
        cd ${KERNEL_SRC}; patch -p1 <../fix-aspm-policy.patch
        cd ${KERNEL_SRC}; patch -p1 <../kbuild-generate-mudules-builtin.patch
        cd ${KERNEL_SRC}; patch -p1 <../add-tiocgdev-ioctl.patch
        #cd ${KERNEL_SRC}; patch -p1 <../fix-nfs-block-count.patch
        cd ${KERNEL_SRC}; patch -p1 <../fix-idr-header-for-drbd-compilation.patch
        sed -i ${KERNEL_SRC}/Makefile -e 's/^EXTRAVERSION.*$$/EXTRAVERSION=${EXTRAVERSION}/'
        touch $@

${KERNEL_SRC}.org/README: ${RHKERSRCDIR}/kernel.spec ${RHKERSRCDIR}/linux-${KERNEL_VER}-${RHKVER}.tar.bz2
        rm -rf ${KERNEL_SRC}.org linux-${KERNEL_VER}-${RHKVER}
        tar xf ${RHKERSRCDIR}/linux-${KERNEL_VER}-${RHKVER}.tar.bz2
        mv linux-${KERNEL_VER}-${RHKVER} ${KERNEL_SRC}.org
        touch $@

${RHKERSRCDIR}/kernel.spec: ${KERNELSRCRPM}
        rm -rf ${RHKERSRCDIR}
        mkdir ${RHKERSRCDIR}
        cd ${RHKERSRCDIR};rpm2cpio ../${KERNELSRCRPM} |cpio -i
        touch $@

rr272x_1x.ko: .compile_mark ${RR272XSRC}
        rm -rf ${RR272XDIR}
        tar xf ${RR272XSRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        make -C ${TOP}/${RR272XDIR}/product/rr272x/linux KERNELDIR=${TOP}/${KERNEL_SRC}
        cp ${RR272XDIR}/product/rr272x/linux/$@ .

megaraid_sas.ko: .compile_mark ${MEGARAID_SRC}
        rm -rf ${MEGARAID_DIR}
        tar xf ${MEGARAID_SRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        make -C ${TOP}/${KERNEL_SRC} M=${TOP}/${MEGARAID_DIR} modules
        cp ${MEGARAID_DIR}/megaraid_sas.ko .

aacraid.ko: .compile_mark ${AACRAIDSRC}
        rm -rf ${AACRAIDDIR}
        mkdir ${AACRAIDDIR}
        cd ${AACRAIDDIR};tar xzf ../${AACRAIDSRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        make -C ${TOP}/${KERNEL_SRC} M=${TOP}/${AACRAIDDIR}/aacraid-${AACRAIDVER}.src/aacraid_source modules
        cp ${AACRAIDDIR}/aacraid-${AACRAIDVER}.src/aacraid_source/aacraid.ko .
        
aoe.ko aoe: .compile_mark ${AOESRC}
        # aoe driver updates
        rm -rf ${AOEDIR} aoe.ko
        tar xf ${AOESRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${AOEDIR}; make KVER=${KVNAME}
        cp ${AOEDIR}/linux/drivers/block/aoe/aoe.ko aoe.ko

e1000e.ko e1000e: .compile_mark ${E1000ESRC}
        rm -rf ${E1000EDIR}
        tar xf ${E1000ESRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${E1000EDIR}/src; make BUILD_KERNEL=${KVNAME}
        cp ${E1000EDIR}/src/e1000e.ko e1000e.ko

igb.ko igb: .compile_mark ${IGBSRC}
        rm -rf ${IGBDIR}
        tar xf ${IGBSRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${IGBDIR}/src; make BUILD_KERNEL=${KVNAME}
        cp ${IGBDIR}/src/igb.ko igb.ko

ixgbe.ko ixgbe: .compile_mark ${IXGBESRC}
        rm -rf ${IXGBEDIR}
        tar xf ${IXGBESRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${IXGBEDIR}/src; make CFLAGS_EXTRA="-DIXGBE_NO_LRO" BUILD_KERNEL=${KVNAME}
        cp ${IXGBEDIR}/src/ixgbe.ko ixgbe.ko

bnx2.ko cnic.ko bnx2x.ko: ${BNX2SRC}
        rm -rf ${BNX2DIR}
        tar xf ${BNX2SRC}
        cd ${BNX2DIR}; patch -p1 <../fix-netxtreme2-compile-error.patch
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${BNX2DIR}; make -C bnx2/src KVER=${KVNAME}
        cd ${BNX2DIR}; make -C bnx2x/src KVER=${KVNAME}
        cp `find ${BNX2DIR} -name bnx2.ko -o -name cnic.ko -o -name bnx2x.ko` .

arcmsr.ko: .compile_mark ${ARECASRC}
        rm -rf ${ARECADIR}
        mkdir ${ARECADIR}; cd ${ARECADIR}; unzip ../${ARECASRC}
        mkdir -p /lib/modules/${KVNAME}
        ln -sf ${TOP}/${KERNEL_SRC} /lib/modules/${KVNAME}/build
        cd ${ARECADIR}; make -C ${TOP}/${KERNEL_SRC} SUBDIRS=${TOP}/${ARECADIR} modules
        cp ${ARECADIR}/arcmsr.ko arcmsr.ko

iscsi_trgt.ko: .compile_mark ${ISCSITARGETSRC}
        rm -rf ${ISCSITARGETDIR}
        tar xf ${ISCSITARGETSRC}
        cd ${ISCSITARGETDIR}; make KSRC=${TOP}/${KERNEL_SRC}
        cp ${ISCSITARGETDIR}/kernel/iscsi_trgt.ko iscsi_trgt.ko

headers_tmp := $(CURDIR)/tmp-headers
headers_dir := $(headers_tmp)/usr/src/linux-headers-${KVNAME}

${HDR_DEB} hdr: .compile_mark headers-control.in headers-postinst.in
        rm -rf $(headers_tmp)
        install -d $(headers_tmp)/DEBIAN $(headers_dir)/include/
        sed -e 's/@KERNEL_VER@/${KERNEL_VER}/' -e 's/@KVNAME@/${KVNAME}/' -e 's/@PKGREL@/${PKGREL}/' <headers-control.in >$(headers_tmp)/DEBIAN/control
        sed -e 's/@@KVNAME@@/${KVNAME}/g'  <headers-postinst.in >$(headers_tmp)/DEBIAN/postinst
        chmod 0755 $(headers_tmp)/DEBIAN/postinst
        install -D -m 644 copyright $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/copyright
        install -D -m 644 changelog.Debian $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/changelog.Debian
        echo "git clone git://git.proxmox.com/git/pve-kernel-2.6.32.git\\ngit checkout ${GITVERSION}" > $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/SOURCE
        gzip -f --best $(headers_tmp)/usr/share/doc/${HDRPACKAGE}/changelog.Debian
        install -m 0644 ${KERNEL_SRC}/.config $(headers_dir)
        install -m 0644 ${KERNEL_SRC}/Module.symvers $(headers_dir)
        cd ${KERNEL_SRC}; find . -path './debian/*' -prune -o -path './include/*' -prune -o -path './Documentation' -prune \
          -o -path './scripts' -prune -o -type f \
          \( -name 'Makefile*' -o -name 'Kconfig*' -o -name 'Kbuild*' -o \
             -name '*.sh' -o -name '*.pl' \) \
          -print | cpio -pd --preserve-modification-time $(headers_dir)
        cd ${KERNEL_SRC}; cp -a include scripts $(headers_dir)
        cd ${KERNEL_SRC}; (find arch/x86 -name include -type d -print | \
                xargs -n1 -i: find : -type f) | \
                cpio -pd --preserve-modification-time $(headers_dir)
        dpkg-deb --build $(headers_tmp) ${HDR_DEB}
        #lintian ${HDR_DEB}

.PHONY: upload
upload: ${DST_DEB} ${PVE_DEB} ${HDR_DEB}
        umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
        mkdir -p /pve/${RELEASE}/extra
        mkdir -p /pve/${RELEASE}/install
        rm -rf /pve/${RELEASE}/extra/${PACKAGE}_*.deb
        rm -rf /pve/${RELEASE}/extra/${HDRPACKAGE}_*.deb
        rm -rf /pve/${RELEASE}/extra/${PVEPKG}_*.deb
        rm -rf /pve/${RELEASE}/extra/Packages*
        cp ${DST_DEB} ${PVE_DEB} ${HDR_DEB} /pve/${RELEASE}/extra
        cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
        umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

.PHONY: distclean
distclean: clean
        rm -rf linux-firmware.git linux-firmware-from-kernel.git ${KERNEL_SRC}.org ${RHKERSRCDIR}

.PHONY: clean
clean:
        rm -rf *~ .compile_mark ${KERNEL_CFG} ${KERNEL_SRC} tmp data proxmox-ve/data *.deb ${AOEDIR} aoe.ko ${headers_tmp} fwdata fwlist.tmp *.ko ${IXGBEDIR} ${E1000EDIR} e1000e.ko ${IGBDIR} igb.ko fwlist-${KVNAME} iscsi_trgt.ko ${ISCSITARGETDIR} ${BNX2DIR} bnx2.ko cnic.ko bnx2x.ko aacraid.ko ${AACRAIDDIR} megaraid_sas.ko ${MEGARAID_DIR} rr272x_1x.ko ${RR272XDIR} ${ARECADIR}.ko ${ARECADIR}
