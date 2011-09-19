#build a 32bit gentoo KVM image
use_linux32

#part nbd0 1 83 +

#format the partition
#format /dev/nbd0p1 ext4

stage_uri cp://./stage3-i686-20110913.tar.bz2
#tree_type snapshot cp://./portage-latest.tar.bz2
#kernel_config_uri cp://./gentoo-x86.conf

#kernel_sources none
#genkernel_opts --makeopts=-j10
#for speed
logger none
cron none

rootpw tp
bootloader grub

#mountfs /dev/nbd0p1 ext4 / noatime,barrier=0 /dev/vda1

net eth0 dhcp

#load qemu module to specify a virtual disk to install our guest
import qemu
pre_partition(){
  local filename=/tmp/qs.img
  create_qemu_img "${filename}" 8G
  #mount the img to /dev/nbd0
  mount_qemu_img "${filename}"
  #nbd_device is populated by mount_qemu_img, it contains the device name,
  #such as /dev/nbd0
  part ${nbd_device} 1 83 +
  #format the partition
  format ${nbd_device}p1 ext4
  mountfs ${nbd_device}p1 ext4 / noatime,barrier=0 /dev/vda1
}

#setup bootloader grub
bootloader_install_device hd0
pre_configure_bootloader(){
  cat > ${chroot_dir}/boot/grub/device.map <<EOF
(hd0)   ${nbd_device}
EOF
}

post_install_portage_tree() {
  cat > ${chroot_dir}/etc/make.conf <<EOF
CHOST="i686-pc-linux-gnu"
CFLAGS="-O2 -march=athlon-xp -pipe"
CXXFLAGS="\${CFLAGS}"
USE="-X -gtk -gnome -kde -qt"
EOF
}
