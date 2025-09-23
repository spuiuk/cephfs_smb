dnf install -y python3-pyyaml python3-jinja2 podman

if [ ${CEPH_REPO}x != "x" ]
then
	dnf config-manager --add-repo ${CEPH_REPO}
	mkdir -p /usr/share/ibm-storage-ceph-license/ && touch /usr/share/ibm-storage-ceph-license/accept
	dnf install -y cephadm
else
	dnf install -y centos-release-ceph-squid
	dnf install -y cephadm
	cephadm add-repo --dev main
	dnf update -y cephadm
fi

if [ ${DEVEL_IMAGE}x != "x" ]
then
	export CEPHADM_IMAGE=${DEVEL_IMAGE}
	echo Using image $CEPHADM_IMAGE
fi

cephadm install ceph-common
export HOST_IP=192.168.145.11
if [ ${CP_PASSWD}x != "x" ]
then
	CEPHADM_CMD="cephadm bootstrap --registry-url cp.icr.io --registry-username cp --registry-password ${CP_PASSWD} --mon-ip=${HOST_IP} --initial-dashboard-password=x --single-host-defaults"
else
       CEPHADM_CMD="cephadm bootstrap --mon-ip=${HOST_IP} --initial-dashboard-password=x --single-host-defaults"
fi

${CEPHADM_CMD}

cat >/root/.ssh/config <<EOF
Host mycephfs??
	StrictHostKeyChecking no
	UpdateHostKeys yes
EOF

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
#ceph smb apply -i /root/resources/smb_cluster.yml

cat << EOF
The SMB service definitions are available in ~/resources
Select the type you need and run the command
ceph smb apply -i ~/resources/<service definition>
EOF
