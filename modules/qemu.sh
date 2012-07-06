create_qemu_img(){
  local filename=$1
  local size=${2:-"100M"}
  local format=${3:-"qcow2"}
  local options=${4:+"-o ${4}"}

  if [ -f ${filename} ]; then
    die "${filename} already exists"
  fi
  if ! spawn "qemu-img create ${options} -f ${format} ${filename} ${size}"; then
    die "pre_partition can't create gentoo image file ${filename}"
  fi
}
nbd_device=
mount_qemu_img(){
  local filename=$1
  local device=${2:-"/dev/nbd0"}
  local opts=$3

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
  if ! qemu-nbd ${opts} -c "${device}" "${filename}"; then
    die "qmeu-nbd failed to load ${filename} and connect it to ${device}"
  fi
  nbd_device="${device}"
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

cleanup_nbd() {
  if [ ! -z "${nbd_device}" ]; then
    debug cleanup_nbd "disconnect nbd device ${nbd_device}"
    if mount | grep ${nbd_device} > /dev/null 2>&1; then
      warn "${nbd_device} is still mounted! not disconnect nbd device."
    elif ! spawn "qemu-nbd -d \"${nbd_device}\""; then
      warn "cleanup_nbd: Failed to disconnect nbd device ${nbd_device}"
    fi
  fi
}

#run cleanup whenever quickstart exits, no matter whether it succeeds or not
post_finishing_cleanup() {
  cleanup_nbd
}

post_failure_cleanup(){
  cleanup_nbd
}
