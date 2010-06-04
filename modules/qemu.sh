qemu_mount_img(){
  local filename=$1
  local device=${2:-/dev/nbd0}

  if [ ! -b /dev/nbd0 ]; then
    #max_part=8 to enable partitions
    modprobe nbd max_part=8
  fi
  if [ ! -b /dev/nbd0 ]; then
    die "qemu_mount_img can't load nbd kernel module"
  fi

  #make sure we are not already mounted
  if mount | grep ${device} > /dev/null 2>&1; then
    die "${device} is already mounted"
  fi

  if ! qemu-nbd -c ${device} ${filename}; then
    die "qmeu-nbd failed to load ${filename} and connect it to ${device}"
  fi
}
