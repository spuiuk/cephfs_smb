# cephfs_smb

Quickly build test clusters running Cephfs with SMB module

By default a multi-host cluster is setup using vagrant to setup 3 virtual machines running CentOS 9 Stream.

We can also setup a single host cluster to use in a resource constrained system by creating a file "devel.mk" with the content
TYPE = singlehost

## Usage:

To start a cluster
```
make ceph_start
```

To stop the cluster
```
make ceph_stop
```

To login to the main host of the cluster
```
make ceph_ssh
```

## Customisations:

There are two levels of customisation, depending on whether the setting affects Vagrant/Make or Ansible.

### Makefile/Vagrant settings (`devel.mk`)

Create a `devel.mk` file in the root of the repository for settings that affect VM creation.

#### TYPE:
Set the type of cluster. This would either be "multihost" for a 3 node cluster or "singlehost" for a single node cluster.

```
TYPE = singlehost
```

#### VAGRANT_BOX:
Vagrant by default creates CentOS 9 vms using the Vagrant box "generic/centos9s". Use the VAGRANT_BOX parameter to set another Vagrant box.

```
VAGRANT_BOX=centos/stream10
```

### Ansible settings (`extra_vars.yml`)

Create `extra_vars.yml` for settings that affect Ansible provisioning. Copy `extra_vars.yml.example` as a starting point. This file is gitignored.

#### CUSTOM_IMAGE:

Use this image to set the repo, registry credentials and the container images to use in the installation. Additional information is available in the [extra_vars.yml.example](extra_vars.yml.example) file.

Example:
```
CUSTOM_VERSION:
  registry:
    url: "quay.io"
    username: "user1"
    password: "aaaaaaaaaaaaaaabbbbccccccccccccccc"
  version: my_version
  repositories:
    default:
      rhel-9: https://example.com/path/to/9/repo.repo
      rhel-10: https://example.com/path/to/10/repo.repo
  images:
    ceph-base: quay.io/youruser/ceph-9-rhel9:yourtag
    grafana_image: quay.io/youruser/grafana-rhel10:yourtag
    prometheus_image: quay.io/youruser/prometheus:yourtag
    samba_metrics_image: quay.io/youruser/samba-metrics-rhel10:yourtag
    samba_image: quay.io/youruser/samba-server-rhel10:yourtag
```
