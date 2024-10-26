# Dotfiles

This repository contains all packages, configuration files and more to automate linux desktop installations for me. I only use Debian or Arch based distros. This repository supports both. At this moment, I only use Xorg on Debian and Wayland on Arch (which is the reason that Wayland related packages will only be installed on Arch). If I need a fresh Linux desktop install, I only need to add environment variables and run one [command](#installation), to replicate my favourite setup. That makes my life a whole lot easier!

You can do whatever you want with my code, since it's licensed under MIT. Use it as inspiration for your own automation setup.

## Installation

**Summary**
Follow these three steps to start the installer:

1. Run `cp .env.example .env`.
2. Add relevant variables to `.env`
3. Run `./install.sh .env` (optional: `--keep-env`, `--skip-bitwarden`)

**Requirements**
To make installing as easy as possible, I have created an install script. This script first makes sure all requirements that are listed in `requirements.txt` are installed. If some required packages are not installed, you will be asked for your sudo password, in order to install the requirements.

The script will install `python3` and `ansible`, in order to run the Ansible playbook.

**Bitwarden**
To securely install my SSH keys, I am using Bitwarden as my secrets manager. In Bitwarden, I created a folder called SSH. The Ansible role `ssh` will loop through each item in that folder and add the ssh public and private keys to the `~/.ssh` folder. It will also add each item to the `~/.ssh/config` file.

Each SSH item in Bitwarden consists of the following:

- username: SSH username
- password: SSH private key
- website: SSH host/ip address
- custom fields:
  - host: SSH alias/host for config file (to be able to run `ssh alias_here`)
  - public_key: SSH public key

If you don't want to make use of Bitwarden, add the option `--skip-bitwarden` to the install command. This will skip the installation and initialization of Bitwarden. Also make sure the role `ssh` has been commented out in `main.yml`, since it requires bitwarden.

**Environment variables**
In order to properly run the commands which need sudo access (such as installing packages), the environment variable `BECOME_PASSWORD` needs to be set. Also, to unlock the Bitwarden Vault, the environment variables `BITWARDEN_EMAIL` and `BITWARDEN_PASSWORD` need to be set. If you have enabled 2FA, the environment variable BITWARDEN_SECRET also needs to be set. To generate a 2FA token, oathtool is used in the script.

- BITWARDEN_EMAIL: the email of your Bitwarden account
- BITWARDEN_PASSWORD: the password of your Bitwarden account
- BITWARDEN_SECRET: the 2FA secret that's used to generate tokens
- BECOME_PASSWORD: the sudo password for your linux user account

Because these environment variables are sensitive and could lead to a security breach if they are stored in plain text on your system, the install script will automatically delete the provided env file. If you don't want this, you can provide the optional `--keep-env` flag to the install script. Also, `.env` files are added to the `.gitignore` file.

## Configuration

If you want to add a package to the installation process, create a folder in the `roles` directory and add a `main.yml` file, which will be automatically executed by Ansible. If you need to add support for multiple Linux distributions, you can add the following to your `main.yml` file:

```yaml
- name: "{{ role_name }} | Checking for Distribution Config: {{ ansible_distribution }}"
  ansible.builtin.stat:
    path: "{{ role_path }}/tasks/{{ ansible_distribution }}.yml"
  register: distribution_config

- name: "{{ role_name }} | Run Tasks: {{ ansible_distribution }}"
  ansible.builtin.include_tasks: "{{ ansible_distribution }}.yml"
  when: distribution_config.stat.exists
```

These tasks will check if you have specified custom Linux distribution tasks. If that is the case, they will be executed. For example, if you want to add support for Debian and Arch, add two files: `Archlinux.yml` and `Debian.yml` with their specific tasks inside.

Then, if you need to execute tasks for all Linux distributions, just add them to the `main.yml` file in the `role` directory.

### Adding app installation

You can add packages several ways, depending on the Linux distribution. Choose the one that suit your needs.

Arch (Pacman)

```yaml
- name: Install Name
  become: true
  pacman:
    name: "name"
    state: present
```

Arch (AUR/Yay)

```yaml
- name: Install Name
  yay: name=name state=present
```

Debian

```yaml
- name: Install name
  become: true
  apt:
    name: "name"
    state: present
```

Debian (Flatpak)

```yaml
- name: Install name (flatpak)
  community.general.flatpak:
    name: com.company.packagename
    state: present
    method: user
```

### Adding config files

Often, you can define configuration files (dotfiles) for your apps. Almost all apps follow the convention of placing config files in `~/.config/{app_name}`. To install those config files automatically, add all config files under roles/{name}/files/config. Then link them with the following Ansible task in /roles/{name}/main.yml.

```yaml
- name: Symlink {name} dotfiles
  ansible.builtin.file:
    src: "{{ role_path }}/files/config"
    dest: "{{ XDG_CONFIG_HOME }}/{name}"
    state: link
    force: no
```

### Adding custom tasks

For custom tasks, add them to your role’s main.yml file. These could include setups beyond package installation, such as additional configuration or post-install tasks.

## Feedback

If you have any feedback or questions, feel free to reach out! I'm always eager to learn and improve.