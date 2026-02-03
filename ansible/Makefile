ifdef EXTRA_VARS
        ANSIBLE_EXTRA_VARS := -e '${EXTRA_VARS}'
endif

common:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory common.yml

bootstrap:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory bootstrap.yml

setup_dc:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory setup_dc.yml

setup_dns:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory setup_dns.yml

test:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory test.yml
