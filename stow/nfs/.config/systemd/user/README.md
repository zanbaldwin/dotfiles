SystemD's user instance does not support mount/automount unit types, as they are inherently a root-only action.

```shell
sudo cp "${HOME}"/.config/systemd/user/*.mount /etc/systemd/system/
sudo cp "${HOME}"/.config/systemd/user/*.automount /etc/systemd/system/
```

Then enable each one:

```shell
sudo systemctl enable --now "home-zan-Books.automount"
sudo systemctl enable --now "home-zan-Drive.automount"
sudo systemctl enable --now "home-zan-Music.automount"
```
