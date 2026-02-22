SystemD's user instance does not support mount/automount unit types, as they are inherently a root-only action.

```shell
sudo cp "${HOME}"/.config/systemd/user/*.mount /etc/systemd/system/
sudo cp "${HOME}"/.config/systemd/user/*.automount /etc/systemd/system/
```

Enable the `.automount`s, which will register the each as _available to mount_
when clicked in Finder. Do not enable the `.mount`s as that will attempt to
mount the NFS on boot which may or may not happen before NetworkManager has
started.

```shell
sudo systemctl enable --now "home-zan-Books.automount"
sudo systemctl enable --now "home-zan-Drive.automount"
sudo systemctl enable --now "home-zan-Music.automount"
```
