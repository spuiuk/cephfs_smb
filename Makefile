-include devel.mk

# Types: singlehost, multihost
TYPE ?= multihost

ssh_key:
	test -s ssh_key || ssh-keygen -N "" -f ssh_key

ceph_ssh:
	make -C ${TYPE} ssh

ceph_start: ssh_key
	if [ -d ${TYPE}/.vagrant ]; then echo -e "\n\nHave an already running Vagrant box\n\n"; \
	else make -C ${TYPE} start; ln -sf ${TYPE}/ssh_key ssh_key; fi

ceph_stop:
	make -C ${TYPE} stop

clean_keys:
	-ssh-keygen -R mycephfs11
	-ssh-keygen -R mycephfs12
	-ssh-keygen -R mycephfs13
	-ssh-keygen -R 192.168.145.11
	-ssh-keygen -R 192.168.145.12
	-ssh-keygen -R 192.168.145.13
	rm -f ssh_key ssh_key.pub

sync_resources:
	make -C ${TYPE} sync_resources
