# To test against the latest ceph devel cluster, add the following to devel.mk
# DEVEL_IMAGE=quay.ceph.io/ceph-ci/ceph:main-centos-stream9-x86_64-devel

SSH_CONFIG := ssh_config
SCP_CMD = scp -F ${SSH_CONFIG}
SSH_CMD = ssh -F ${SSH_CONFIG}
RSYNC_CMD = rsync -e '${SSH_CMD}'

SAMBA_DEV = ./samba_dev
CEPH_CONF = ${SAMBA_DEV}/ceph/
WORKSPACES = ${SAMBA_DEV}/workspaces/

SAMBA_DEV_NAME = samba_dev
SAMBA_DEV_IMAGE = quay.io/spuiuk/samba_cephfs:samba_dev

_create_auth:
	${SSH_CMD} root@mycephfs11 "if ! [ -a /etc/ceph/ceph.client.samba_dev.keyring ]; \
				then \
				ceph fs authorize mycephfs client.samba_dev / rw > /tmp/ceph.client.samba_dev.keyring && \
				mv -f /tmp/ceph.client.samba_dev.keyring /etc/ceph/; \
				fi; "

copy_ceph_conf: _create_auth
	rm -rf ${CEPH_CONF}/*
	${SCP_CMD} root@mycephfs11:/etc/ceph/* ${CEPH_CONF}
	VOLPATH=$(shell ${SSH_CMD} root@mycephfs11 "ceph fs subvolume getpath mycephfs smbshares") \
	${WORKSPACES}/bin/build_samba_conf.sh > ${CEPH_CONF}/cephfs-samba.conf

samba_start: copy_ceph_conf
	podman run -d \
		--name ${SAMBA_DEV_NAME} \
		--volume ${CEPH_CONF}:/config/ceph \
		--volume ${WORKSPACES}:/workspaces/samba_cephfs \
		--cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
		--cap-add=NET_ADMIN --cap-add=NET_RAW --cap-add=SYS_ADMIN \
		${SAMBA_DEV_IMAGE}

samba_stop:
	podman kill ${SAMBA_DEV_NAME}
	podman rm ${SAMBA_DEV_NAME}

samba_exec:
	podman exec -it ${SAMBA_DEV_NAME} /bin/bash


.PHONY: _create_auth copy_ceph_conf samba_start samba_stop samba_exec
