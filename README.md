proxomox
========

About bug CVE-2014-3519
- http://www.openwall.com/lists/oss-security/2014/06/24/16
- http://www.webhostingtalk.com/showthread.php?t=1387714

Updated kernel packages that fix three security issues. But I'm using proxmox 2.3 (debian 6) and I don't want move to proxmox 3.x. How to update kernel package?

- apt-get install git -y
- git clone git://git.proxmox.com/git/pve-kernel-2.6.32.git
- apt-get install libncurses5-dev rpm2cpio lintian fakeroot unzip -y
- cd pve-kernel-2.6.32
- Download Makefile above or edit Makefile like "gcc --version|grep "4\.4\.5" || false".
- cp /boot/config-2.6.32-21-pve ./.config
- make clean
- make
- dpkg -i pve-*.deb
- reboot server and make sure your server running pve-kernel-2.6.32-30.
