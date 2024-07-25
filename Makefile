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

