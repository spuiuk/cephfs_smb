-include ../devel.mk

SSH_CONFIG := ../ssh_config
SSH_CMD = ssh -F ${SSH_CONFIG}
EXTRA_VARS="INSTALL_TYPE=singlehost CEPH_REPO=${CEPH_REPO} CP_PASSWD=${CP_PASSWD} DEVEL_IMAGE=${DEVEL_IMAGE} SMB_IMAGE=${SMB_IMAGE}"

ifdef VAGRANT_BOX
	VAGRANT_VARS=VAGRANT_BOX=${VAGRANT_BOX}
endif

ssh:
	${SSH_CMD} root@mycephfs11

_vagrant_start:
	${VAGRANT_VARS} vagrant up
	vagrant ssh-config|sed 's/IdentityFile.*/IdentityFile .\/ssh_key/'|sed 's/User vagrant/User root/' > ../ssh_config

_vagrant_stop:
	vagrant destroy -f
	rm -rf .vagrant ../ssh_config

_ansible_prep:
	ln -sf ../singlehost/ansible_inventory ../ansible/inventory

_ansible_cleanup:
	rm ../ansible/inventory

start: _vagrant_start provision

stop: _vagrant_stop _ansible_cleanup

provision: _ansible_prep
	EXTRA_VARS=${EXTRA_VARS} make -C ../ansible common bootstrap

_tcpdump:
	-${SSH_CMD} root@mycephfs11 "dnf install -y tcpdump"
	-${SSH_CMD} root@mycephfs11 "rm -f /tmp/out.pcap; tcpdump -w /tmp/out.pcap -i eth1"
	/bin/true

tcpdump: _tcpdump
	${SCP_CMD} root@mycephfs11:/tmp/out.pcap /tmp/out.pcap
	wireshark /tmp/out.pcap

.PHONY: ssh _vagrant_start _vagrant_stop _ansible_prep _ansible_cleanup start stop provision _tcpdump tcpdump
