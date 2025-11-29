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
