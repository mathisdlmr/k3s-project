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
.
├── groupe_vars  # Contain variables (like IP address) for a group of machines. We can create a `host_vars` directory when variables concern only a specific machine
│   ├── all.example.yml
│   └── all.yml
├── inventory  # List managed machines. Can be splitted in `production/`, `staging/`, ...
│   └── hosts.yml
├── playbooks  # Ansible's core : declare tasks and modules we will run
│   └── site.yml
├── roles
│   ├── argocd_bootstrap
│   │   ├── defaults
│   │   │   └── main.yml
│   │   └── tasks
│   │       └── main.yml
│   ├── cilium
│   │   ├── defaults
│   │   │   └── main.yml
│   │   └── tasks
│   │       └── main.yml
│   ├── common
│   │   ├── handlers
│   │   │   └── main.yml
│   │   └── tasks
│   │       ├── audit.yml
│   │       ├── firewall.yml
│   │       ├── kernel.yml
│   │       ├── main.yml
│   │       ├── packages.yml
│   │       ├── ssh.yml
│   │       └── tailscale.yml
│   ├── disable_cstates
│   │   └── tasks
│   │       └── main.yml
│   └── k3s_server
│       ├── defaults
│       │   └── main.yml
│       ├── handlers
│       │   └── main.yml
│       ├── tasks
│       │   └── main.yml
│       └── templates
│           └── config.yaml.j2
├── ansible.cfg
├── Makefile
├── README.md
└── requirements.yml
```

Other ideas : 
- Separate an init node from a classic node in terms or role, rather than using a boolean

