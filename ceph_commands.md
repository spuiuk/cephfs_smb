# Ceph commands:

Commands for using ceph.

### Cluster status
```
ceph -s
```

### Cluster hosts
```
ceph orch host ls
```

### List Cephfs volumes
```
ceph fs volume ls
```

### Create Cephfs volume
```
ceph fs volume create mycephfs
```
Creates cephfs volume mycephfs

### List subvolumes for a volume
```
ceph fs subvolume ls mycephfs
```

### Create Cephfs subvolume
```
ceph fs subvolume create mycephfs smbshares  --mode 0777 
```
Creates subvolume smbshares within cephfs volume mycephfs

## Ceph MGR

### List manager modules
```
ceph mgr module ls
```

### Enable manager module
```
ceph mgr module enable smb
```
We enable smb mgr module

## Ceph SMB module

### List samba clusters
```
ceph smb cluster ls
```

### Add a new samba cluster
```
ceph smb cluster create mysmb user --define-user-pass test1%x
```
Where we create a samba cluster named: mysmb. We add simple username/password authentication for user test1 with password 'x'

### List samba shares on cluster
```
ceph smb share ls mysmb
```
where mysmb is the samba cluster name

### Create new samba share on cluster
```
ceph smb share create mysmb smb1 mycephfs /smb1 --subvolume=smbshares
```
Where mysmb is the samba cluster id within cephfs volume mycephfs.
/smb1 is a directory within the subvolume smbshares.

## Ceph config

### List configuration options available
```
ceph config ls
```

### List daemons available
```
ceph orch ps
```

### List configuration options set for a daemon
```
ceph config show mgr.mycephfs11.crupiw
```
or
```
ceph config show-with-defaults mgr.mycephfs11.crupiw
```
where mgr.mycephfs11.crupiw is the daemon from the 1st column of the previous command.
