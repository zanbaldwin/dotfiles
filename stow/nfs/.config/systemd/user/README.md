SystemD's user instance does not support mount/automount unit types, as they are inherently a root-only action.

```shell
sudo cp "${HOME}"/.config/systemd/user/*.mount /etc/systemd/system/
```
