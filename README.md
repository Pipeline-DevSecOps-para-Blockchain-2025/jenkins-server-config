# Setup for a Secure Jenkins Server on Fedora

## cloud-init

### Verifying the config

```console
$ cloud-init schema -i ./example-instance-data.json -c ./cloud-config.yaml --annotate
Valid schema ./cloud-config.yaml
```

To verify that the template output is correct:

```console
$ cloud-init devel render -i ./example-instance-data.json ./cloud-config.yaml
#cloud-config

hostname: 'jenkins-server-example'

packages:
  - kitty-terminfo
```

### Testing with QEMU

Prepare the cloud-init config:

```console
$ cloud-localds seed.img cloud-config.yaml example-meta-data.yaml
```

Then load a virtual machine:

```console
$ qemu-system-x86_64 -m 1024 -net nic -net user \
  -drive file=Fedora-Cloud-Base-UEFI-UKI-42-1.1.x86_64.qcow2,index=0,format=qcow2,media=disk \
  -drive file=seed.img,index=1,media=cdrom \
  -machine accel=kvm:tcg
```

See the [official documentation](https://cloudinit.readthedocs.io/en/latest/howto/launch_qemu.html "Run cloud-init locally with QEMU") for more details.
