# Ubuntu w/ ZFS

## ZFS Setup
**Immediately** after installation:

```shell
sudo zfs snapshot -r "rpool@clean-install-$(date +%F)"
sudo apt install 'zfs-dkms' 'zfs-initramfs'
# Update existing (`-u`) initramfs for Kernel version `all`:
sudo update-initramfs -u -k all
```

There are real-world reports that snapshots on `bpool` can break GRUB's ability to read it in some cases. If you later set up automatic snapshot tools, **explicitly exclude** `bpool`.

### Dock Settings
ZFS pools (`boot`, `root`) will show up in the dock, but can't be mounted because they were already mounted at boot. It's annoying.
> Disable “show volumes/devices” in the dock settings.

### GRUB Support
When GRUB detects EFI systems with non-writable filesystems (like ZFS), it recognizes that it can't write to the grubenv file, so it sets `recordfail_broken=1`. This unconditionally sets a 30-second timeout, completely ignoring the `GRUB_TIMEOUT=0` setting.
> Set `GRUB_RECORDFAIL_TIMEOUT=0` in `/etc/default/grub`.