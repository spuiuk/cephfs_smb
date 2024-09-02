dnf install -y centos-release-ceph-reef
dnf install -y cephadm
cephadm add-repo --dev main
dnf update -y cephadm

#export CEPHADM_IMAGE="quay.ceph.io/ceph-ci/ceph:main"
cephadm install ceph-common
export HOST_IP=192.168.145.11
cephadm bootstrap --mon-ip=${HOST_IP} --initial-dashboard-password="x"

cat >/root/.ssh/config <<EOF
Host mycephfs??
	StrictHostKeyChecking no
	UpdateHostKeys yes
EOF

for host in mycephfs12 mycephfs13
do
	ssh-copy-id -f -i /etc/ceph/ceph.pub root@${host}
	ssh ${host} dnf install -y podman
	ceph orch host add ${host}
done

ceph orch apply osd --all-available-devices
while ! ceph -s|grep HEALTH_OK; do sleep 5; done

ceph fs volume create mycephfs
ceph fs subvolume create mycephfs smbshares  --mode 0777

ceph mgr module enable orchestrator
ceph mgr module enable smb
# Perform other tasks before creating smb resources
# This is to allow enough time for smb module to come up

dnf install -y ceph-fuse samba-client
mkdir /mnt-cephfs && ceph-fuse /mnt-cephfs/

# Create smb resources
sleep 10
ceph smb apply -i /root/resources/smb_cluster.yml

