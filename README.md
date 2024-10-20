# Rebuildr

The Environment variable BW_SESSION can be used to retrieve passwords from Bitwarden.

Run `sudo ./install.sh file.env` to kick of the installation process. Optionally use the `--keep-env` flag to prevent removing the provided env file.

## Adding app installation

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
- name: Install Zed (flatpak)
  community.general.flatpak:
    name: dev.zed.Zed
    state: present
    method: user
```
