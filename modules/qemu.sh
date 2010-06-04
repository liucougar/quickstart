create_qemu_img(){
  local filename=$1
  local size=${2:-"100M"}
  local format=${3:-"qcow2"}

  if [ -f ${filename} ]; then
    die "${filename} already exists"
  fi
  if ! spawn "qemu-img create -f ${format} ${filename} ${size}"; then
    die "pre_partition can't create gentoo image file ${filename}"
  fi
}
mount_qemu_img(){
  local filename=$1
  local device=${2:-"/dev/nbd0"}

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

  if get_device_size_in_mb ${device} > /dev/null 2>&1; then
  #if echo q | fdisk ${device} > /dev/null 2>&1; then
    ps aux | grep qemu-nbd | grep ${device}
    die "${device} is already connected."
  fi
  if ! qemu-nbd -c "${device}" "${filename}"; then
    die "qmeu-nbd failed to load ${filename} and connect it to ${device}"
  fi
  local timeout=10
  local count=0
  while ! get_device_size_in_mb ${device} > /dev/null 2>&1; do
    if [ $count -gt $timeout ]; then
      die "Timeout while waiting for nbd to come online!"
      break
    fi
    sleep 1
    count=$(expr $count + 1)
  done
}
