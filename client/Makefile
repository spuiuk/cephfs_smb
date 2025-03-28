-include ../devel.mk

SSH_CONFIG := ../ssh_config
SCP_CMD = scp -F ${SSH_CONFIG}
SSH_CMD = ssh -F ${SSH_CONFIG}
RSYNC_CMD = rsync -e '${SSH_CMD}'

CLIENT_HOST = root@mycephfs10

ssh:
	${SSH_CMD} ${CLIENT_HOST}

vagrant:
	vagrant up

copy_keys:
	ln -sf ../ssh_key ssh_key && ln -sf ../ssh_key.pub ssh_key.pub
	${SCP_CMD} ssh_key ${CLIENT_HOST}:/root/.ssh/id_rsa
	${SSH_CMD} ${CLIENT_HOST} "chmod 0700 /root/.ssh/id_rsa"

start: vagrant copy_keys provision

stop:
	vagrant destroy -f
	rm -rf .vagrant ssh_key ssh_key.pub

provision:
	${SCP_CMD} provision.sh ${CLIENT_HOST}:/tmp/provision.sh
	${SSH_CMD} ${CLIENT_HOST} "/bin/bash -x /tmp/provision.sh"
	${SCP_CMD} smb.conf ${CLIENT_HOST}:/etc/samba/smb.conf

.PHONY: ssh vagrant copy_keys start stop provision
