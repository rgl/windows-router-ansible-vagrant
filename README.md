# About

This is an example windows router provisioned by ansible in a vagrant environment.

Vagrant VMs need to have a management network wich is NATted by the host,
but that makes it difficult to play with the windows router, so this essentially
adds a secondary network interface that is used for routing, and replaces the
adds a default route to use our router in `eth1`. So everything that would be
normally done at `eth0` must be done in `eth1`.

The network is setup as:

![](diagram.png)

**NB** The dotted lines represent a network connection that is not directly used,
instead, the traffic in those nodes goes through `eth1` and is routed by the
`router` machine.

**NB** For a non-ansible equivalent of this environment see
[rgl/windows-router-vagrant](https://github.com/rgl/windows-router-vagrant).

**NB** For a debian linux equivalent of this environment see
[rgl/debian-router-vagrant](https://github.com/rgl/debian-router-vagrant).

## Usage

Install the [base windows 2022 box](https://github.com/rgl/windows-vagrant).

Install ansible in a python venv:

```bash
# NB this will use sudo to install system dependencies.
bash ansible-install.sh
```

Start this environment:

```bash
source ansible-env.sh
time vagrant up --provider=libvirt --no-destroy-on-error --no-tty
```

You can later trigger the ansible playbook execution with `vagrant`:

```bash
vagrant up --provision
```

You can also directly trigger the ansible playbook execution with
`ansible-playbook`:

```bash
ansible-inventory --list --yaml
ansible-playbook playbook.yml --check --diff #-vvv
ansible-playbook playbook.yml --diff #-vvv
```

## Network Packet Capture

Login into the VM, install npcap (its on the Desktop), and run Wireshark.

## Reference

* https://www.vagrantup.com/docs/provisioning/ansible_intro
* https://www.vagrantup.com/docs/provisioning/ansible_common
* https://www.vagrantup.com/docs/provisioning/ansible
* https://docs.ansible.com/ansible-core/2.12/user_guide/playbooks.html
* https://docs.ansible.com/ansible-core/2.12/user_guide/playbooks_best_practices.html
* https://docs.ansible.com/ansible-core/2.12/reference_appendices/YAMLSyntax.html
