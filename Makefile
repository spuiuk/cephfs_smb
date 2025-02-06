-include devel.mk

# Types: singlehost, multihost
TYPE ?= multihost

ssh:
	make -C ${TYPE} ssh

start:
	make -C ${TYPE} start

stop: clean_keys
	make -C ${TYPE} stop

clean_keys:
	-ssh-keygen -R mycephfs11
	-ssh-keygen -R mycephfs12
	-ssh-keygen -R mycephfs13
	-ssh-keygen -R 192.168.145.11
	-ssh-keygen -R 192.168.145.12
	-ssh-keygen -R 192.168.145.13

sync_resources:
	make -C ${TYPE} sync_resources
