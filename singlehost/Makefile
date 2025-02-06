-include ../devel.mk

SSH_CONFIG := ../ssh_config
SCP_CMD = scp -F ${SSH_CONFIG}
SSH_CMD = ssh -F ${SSH_CONFIG}

# Dev branch to use - defaults to main
DEVEL_IMAGE ?= quay.ceph.io/ceph-ci/ceph:main

ssh:
	${SSH_CMD} root@mycephfs11

vagrant:
	rm -f ssh_key ssh_key.pub && ssh-keygen -N "" -f ssh_key
	vagrant up

copy_keys:
	${SCP_CMD} ssh_key root@mycephfs11:/root/.ssh/id_rsa
	${SSH_CMD} root@mycephfs11 "chmod 0700 /root/.ssh/id_rsa"

sync_resources:
	${SCP_CMD} -r  ../resources root@mycephfs11:

start: vagrant copy_keys provision

stop:
	vagrant destroy -f
	rm -rf .vagrant ssh_key ssh_key.pub

provision: sync_resources
	${SCP_CMD} provision.sh root@mycephfs11:/tmp/provision.sh
	${SSH_CMD} root@mycephfs11 "DEVEL_IMAGE=${DEVEL_IMAGE} SMB_IMAGE=${SMB_IMAGE} /bin/bash -x /tmp/provision.sh"

_tcpdump:
	-${SSH_CMD} root@mycephfs11 "dnf install -y tcpdump"
	-${SSH_CMD} root@mycephfs11 "rm -f /tmp/out.pcap; tcpdump -w /tmp/out.pcap -i eth1"
	/bin/true

tcpdump: _tcpdump
	${SCP_CMD} root@mycephfs11:/tmp/out.pcap /tmp/out.pcap
	wireshark /tmp/out.pcap

.PHONY: ssh vagrant copy_keys start stop provision
