dnf install -y centos-release-ceph-reef
dnf install -y cephadm
cephadm add-repo --dev main
dnf update -y cephadm

export CEPHADM_IMAGE=${DEVEL_IMAGE}
echo Using image $CEPHADM_IMAGE
cephadm install ceph-common
export HOST_IP=192.168.145.11
cephadm bootstrap --mon-ip=${HOST_IP} --initial-dashboard-password="x"

cat >/root/.ssh/config <<EOF
Host mycephfs??
	StrictHostKeyChecking no
	UpdateHostKeys yes
EOF

for h in 12 13
do
	host="mycephfs${h}"
	ip="192.168.145.${h}"
	while ! ssh root@${host} /bin/true; do sleep 1; done
	ssh-copy-id -f -i /etc/ceph/ceph.pub root@${host}
	ssh ${host} dnf install -y podman
	ceph orch host add ${host} ${ip}
	ceph orch host label add ${host} smb
done
ceph orch host label add mycephfs11 smb

ceph orch apply osd --all-available-devices
while ! ceph -s|grep HEALTH_OK; do sleep 5; done

if [ ${SMB_IMAGE}x != "x" ]
then
	ceph config set mgr mgr/cephadm/container_image_samba ${SMB_IMAGE}
fi

# Create volume cephfs and wait until it is available
ceph fs volume create mycephfs
while ! ceph fs ls|grep mycephfs; do sleep 5; done

# If subvolume smbshares doesn't exist, attempt to create it and wait.
while ! ceph fs subvolume ls mycephfs|grep smbshares
do
	ceph fs subvolume create mycephfs smbshares  --mode 0777
	sleep 5
done

ceph mgr module enable orchestrator
ceph mgr module enable smb

# Perform other tasks before creating smb resources
dnf install -y ceph-fuse samba-client
mkdir /mnt-cephfs && ceph-fuse /mnt-cephfs/

# Wait for smb module to be enabled
#sleep 10
# Create smb resources
# ceph smb apply -i /root/resources/smb_cluster.yml

cat << EOF
The SMB service definitions are available in ~/resources
Select the type you need and run the command
ceph smb apply -i ~/resources/<service definition>
EOF
