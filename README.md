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

You can do the following customisations by setting variabled in the file devel.mk in the root of the repository

### TYPE:
Set the type of cluster. This would either be "multihost" for a 3 node cluster or "singlehost" for a single node cluster.

```
TYPE = singlehost
```
### VAGRANT_BOX:
Vagrant by default creates CentOS 9 vms using the Vagrant box "generic/centos9s". Use the VAGRANT_BOX parameter to set another Vagrant box.

```
VAGRANT_BOX=centos/stream10
```

### DEVEL_IMAGE:
Use this variable to point to the container image to use. Use this when testing out your own container image of a ceph build.

```
DEVEL_IMAGE = quay.io/spuiuk/ceph_test:latest
```

### SMB_IMAGE:
Use this variable to point to the samba container used for the SMB service. Use it when testing your own samba container build.

```
SMB_IMAGE = quay.io/spuiuk/smb_test:latest
```

### Setting up downstream:

To test downstream, you require to set 2 variables

### CEPH_REPO:
This is the URL to the repo file for the downstream build.

### CP_PASSWD:
The production entitlement key. Follow instructions [here](https://github.ibm.com/alchemy-registry/image-iam/blob/master/obtaining_entitlement.md).

```
CEPH_REPO = https://xxx.yyy.zzz.com/pub/abc/defg/test-rhel9.repo
CP_PASSWD = aaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccdddddddddddddddddd
```
