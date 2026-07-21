This Ansible project is based on these Ansible tutorials : 
- https://docs.ansible.com/projects/ansible/latest/
- https://oneuptime.com/blog/post/2026-02-21-how-to-organize-ansible-project-directory-structure/view
- https://oneuptime.com/blog/post/2026-02-21-configure-ansible-cfg-project/view

> [!TIP]
> Most of tutorials I found online were using the `yml` extension insted of `yaml`, probably for Windows compatibility or something like that.
>
> To avoid naming a file `.yaml` and declaring it as `.yml` in an other file, I will be only using the `.yml`extension for this part of the project

## Project Structure

```sh
ansible/
├── ansible.cfg
├── groupe_vars    # Contain variables (like IP address) for a group of machines. We can create a `host_vars` directory when variables concern only a specific machine
│   └── all.yml
├── inventory      # List managed machines. Can be splitted in `production/`, `staging/`, ...
│   └── hosts.yml
├── Makefile
├── playbooks      # Ansible's core : declare tasks and modules we will run
│   └── site.yml
├── README.md
├── requirements.yml
└── roles
```

Autres idées : 
- Séparer une node d'init d'une node classique en termes de role, plutôt que d'utiliser un booléan ?


