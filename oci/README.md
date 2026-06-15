On a fresh installation of Silverblue:

- `bash oci/upgrade.sh` to compile and switch
- Enable Kanata support:
  - `sudo groupadd --system 'uinput'`
  - `grep -q "^input:" /etc/group || getent group input >> /etc/group` (copy atomic group to writable sysconfig)
  - `sudo usermod -aG uinput "${USER}"`
  - `sudo usermod -aG input "${USER}"`
  - `cargo install --locked 'kanata'`
  - `systemctl --user enable --now 'kanata'`
