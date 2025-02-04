dnf install -y centos-release-ceph-reef
dnf install -y cephadm
cephadm add-repo --dev main
dnf update -y cephadm

export CEPHADM_IMAGE=${DEVEL_IMAGE}
echo Using image $CEPHADM_IMAGE
cephadm install ceph-common
export HOST_IP=192.168.145.11

# Prepare base bootstrap command
BOOTSTRAP_CMD="cephadm bootstrap --mon-ip=${HOST_IP} --initial-dashboard-password='x'"

# Append --shared_ceph_folder if provided
if [ ! -z "$CEPH_SHARED_FOLDER" ]; then
    BOOTSTRAP_CMD="$BOOTSTRAP_CMD --shared_ceph_folder=$CEPH_SHARED_FOLDER"
fi

# Run the bootstrap command
$BOOTSTRAP_CMD

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
sleep 10

# Create smb resources
ceph smb apply -i /root/resources/smb_cluster.yml

