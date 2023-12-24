#### Running a Local DNS Server

SystemD automatically runs a stub DNS server on port 53. To disable this:
1. Make a backup of the generated DNS config:
   `sudo cp /run/systemd/resolve/resolv.conf /etc/systemd/run-systemd-resolve-resolv.conf.bak`
2. Set `DNSStubListener` to `no` in `/etc/systemd/resolved.conf`
3. Symbolically link this config file to `/run/systemd/resolve/resolv.conf`:
   `sudo ln -s /run/systemd/resolve/resolv.conf /etc/systemd/resolved.conf`
4. Restart or `sudo systemctl restart systemd-resolved`
