ifdef EXTRA_VARS
        ANSIBLE_EXTRA_VARS := -e '${EXTRA_VARS}'
endif

common:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory common.yml

bootstrap:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory bootstrap.yml

test:
	ansible-playbook ${ANSIBLE_EXTRA_VARS} -i inventory test.yml
