#!/bin/sh
## QEMU libvirt hook that automatically allocates the required Hugepages
## when starting a VM and deallocates when the VM is shutdown.
##
## Install to `/etc/libvirt/hooks/qemu`.
## Requires `xmllint` and GNU `awk` to calculate memory requirements.
set -eu

# see https://www.libvirt.org/hooks.html
OBJECT="${1:?}"
OPERATION="${2:?}"
SUB_OPERATION="${3:?}"
#EXTRA_ARGUMENT = "${4:?}"
HOOK_DATA="$(cat)"

STATE=/run/libvirt/hugepages-hook
LOCK_FILE="${STATE}.lock"
DATA_FILE="${STATE}/${OBJECT}.nr_hugepages"
mkdir -p "${STATE}"

xpath() {
  printf '%s' "${HOOK_DATA}" | xmllint --xpath "${1}" -
}

hugepage_size() {
  awk '/Hugepagesize:/ {print $2 * 1024}' /proc/meminfo
}

guest_memory_size() {
  unit="$(xpath 'normalize-space(/domain/memory/@unit)' | tr '[:upper:]' '[:lower:]')"
  value="$(xpath 'normalize-space(/domain/memory)')"

  # see https://libvirt.org/formatdomain.html#memory-allocation
  case "${unit}" in
    b | bytes)
      echo "$((value))"
      ;;
    "" | k | kib)
      echo "$((value * 1024))"
      ;;
    m | mib)
      echo "$((value * 1024 * 1024))"
      ;;
    g | gib)
      echo "$((value * 1024 * 1024 * 1024))"
      ;;
    t | tib)
      echo "$((value * 1024 * 1024 * 1024 * 1024))"
      ;;
    kb)
      echo "$((value * 1000))"
      ;;
    mb)
      echo "$((value * 1000 * 1000))"
      ;;
    gb)
      echo "$((value * 1000 * 1000 * 1000))"
      ;;
    tb)
      echo "$((value * 1000 * 1000 * 1000 * 1000))"
      ;;
    *)
      echo "Unknown memory unit '${unit}' for size '${value}'" > /dev/stderr
      exit 1
      ;;
  esac
}

guest_memory_pages() {
  hugepagesz="$(hugepage_size)"
  guestmemsz="$(guest_memory_size)"

  echo "$(((guestmemsz + hugepagesz - 1) / hugepagesz))"
}

alloc_guest_pages() {
  needed="$(guest_memory_pages)"
  initial="$(sysctl -n vm.nr_hugepages)"
  expected="$((initial + needed))"
  final="$(sysctl -n -w vm.nr_hugepages="${expected}")"
  allocated="$((final - initial))"
  echo "${allocated}" > "${DATA_FILE}"

  if [ "${allocated}" -ne "${needed}" ]; then
    echo "Could not allocate enough hugepages: needed=${needed}, allocated=${allocated}" > /dev/stderr
    echo "Skipping ${OBJECT} initialization. Memory will be deallocated on the release stage" > /dev/stderr
    return 1
  fi

  echo "Allocated ${allocated} hugepages for ${OBJECT}: initial=${initial} => final=${final}"
}

free_guest_pages() {
  allocated="$(cat "${DATA_FILE}")"
  initial="$(sysctl -n vm.nr_hugepages)"
  expected="$((initial - allocated))"
  final="$(sysctl -n -w vm.nr_hugepages="${expected}")"
  freed="$((initial - final))"
  echo "$((allocated - freed))" > "${DATA_FILE}"

  if [ "${freed}" -ne "${allocated}" ]; then
    echo "Could not free all allocated hugepages: freed=${freed}, allocated=${allocated}" > /dev/stderr
    echo "Hugepages from ${OBJECT} might have leaked" > /dev/stderr
    return 1
  fi

  echo "Freed ${freed} hugepages from ${OBJECT}: initial=${initial} => final=${final}"
}

with_lock() {
  exec 9> "${LOCK_FILE}"
  flock -x 9
  "$@"
  exec 9>&-
}

## Skip domain if hugepages are not requested
needs_hugepages="$(xpath 'boolean(/domain/memoryBacking/hugepages)')"
if [ "${needs_hugepages}" != true ]; then
  exit 0
fi

## Run startup or finish hooks
case "${OPERATION}:${SUB_OPERATION}" in
  prepare:begin)
    with_lock alloc_guest_pages
    ;;
  release:end)
    with_lock free_guest_pages
    ;;
  *) ;;
esac
