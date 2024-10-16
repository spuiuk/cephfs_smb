# cephfs_smb

Quickly build test clusters running Cephfs with SMB module

By default a multi-host cluster is setup using vagrant to setup 3 virtual machines running CentOS 9 Stream.

We can also setup a single host cluster to use in a resource constrained system by creating a file "devel.mk" with the content
TYPE = singlehost

## Usage:

To start a cluster
```
make start
```

To stop the cluster
```
make stop
```

To login to the main host of the cluster
```
make ssh
```
