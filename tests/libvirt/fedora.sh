#!/bin/sh
## Set up a Fedora Cloud 43 image for local tests.
set -eu
cd "$(dirname "${0}")"

cleanup() {
  rm -f "${SEED:-}" "${IMAGE:-}" || :
}
trap 'cleanup' EXIT INT TERM HUP

# see storage/testing.pool.xml
if ! virsh pool-list --name --all | grep -qFx testing; then
  virsh pool-define storage/testing.pool.xml --validate
  virsh pool-build --pool testing
fi
if ! virsh pool-list --name | grep -qFx testing; then
  virsh pool-autostart --pool testing
  virsh pool-start --pool testing
fi

# see network/vm-net.xml
if ! virsh net-list --name --all | grep -qFx testing; then
  virsh net-define network/testing.xml --validate
fi
if ! virsh net-list --name | grep -qFx testing; then
  virsh net-autostart --network testing
  virsh net-start --network testing
fi

# see storage/fedora-base.xml
SOURCE='https://edgeuno-bog2.mm.fcix.net/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2'
if ! virsh vol-key --pool testing --vol fedora-base.qcow2 > /dev/null 2>&1; then
  virsh vol-create --pool testing storage/fedora-base.xml --validate
  IMAGE="$(mktemp --tmpdir 'fedora-XXXXXXXXXX.qcow2')"
  curl -fL "${SOURCE}" -o "${IMAGE}"
  virsh vol-upload --pool testing --vol fedora-base.qcow2 "${IMAGE}"
fi

# see storage/fedora.xml
if virsh vol-key --pool testing --vol fedora.qcow2 > /dev/null 2>&1; then
  virsh vol-delete --pool testing --vol fedora.qcow2
fi
virsh vol-create --pool testing storage/fedora.xml --validate

# see storage/fedora-seed.xml
if ! virsh vol-key --pool testing --vol fedora-seed.img > /dev/null 2>&1; then
  virsh vol-create --pool testing storage/fedora-seed.xml --validate
fi

# see ../../cloud-config.yaml
SEED="$(mktemp --tmpdir 'seed-XXXXXXXXXX.img')"
cloud-localds "${SEED}" ../../cloud-config.yaml ../meta-data.yaml
virsh vol-upload --pool testing --vol fedora-seed.img "${SEED}"

# see qemu/fedora.xml
virsh create qemu/fedora.xml --validate --autodestroy --console
