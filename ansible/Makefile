# Makefile

.PHONY: setup-ansible ping deploy lint check

setup-ansible:
	python3 -m venv ./ansible-venv
	./ansible-venv/bin/pip install --upgrade pip
	./ansible-venv/bin/pip install ansible ansible-lint molecule
	./ansible-venv/bin/ansible --version

ping:
	ansible all -m ping -i inventory/hosts.yml

deploy:
	ansible-playbook playbooks/site.yml -i inventory/hosts.yml --ask-vault-pass

lint:
	ansible-lint playbooks/ roles/

check:
	ansible-playbook playbooks/site.yml -i inventory/hosts.yml --check --diff --ask-vault-pass

default:
	cat ./Makefile