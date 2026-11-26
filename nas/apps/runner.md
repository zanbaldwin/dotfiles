# NAS Overhaul Guide

## 1. Forgejo Runner in a VM

### Why

The `dind` service in `apps/compose.git.yaml` runs with `privileged: true`. The Forgejo security documentation says that a privileged job container can "operate as `root` on the Forgejo Runner machine". At the moment, that machine is the NAS.

A VM moves this risk off the NAS host. A workflow can then damage only the VM, and you can delete and rebuild the VM in minutes. The Forgejo documentation recommends a VM for this reason.

An LXC container does not give the same protection. LXC containers share the host kernel, so a container escape reaches the NAS.

### 1.1 Create a network bridge

By default, a TrueNAS VM cannot connect to the TrueNAS host. The runner must connect to `git.lan.zanbaldwin.com`, which is the NAS, so the VM needs a bridge.

> [!WARNING]
> This procedure changes the NAS network configuration. Do it from a local console or the local network, not over Tailscale. TrueNAS reverts the change after 60 seconds if you do not confirm it.

1. Stop all apps and VMs.
2. Go to **System > Network**.
3. Edit the physical interface. Remove its static IP address.
4. Click **Add**. Set **Type** to **Bridge** and **Name** to `br0`.
5. Add the physical interface to **Bridge Members**.
6. Give `br0` the static IP address that the physical interface had.
7. Click **Test Changes**.
8. Open the TrueNAS UI again at the same address. If it loads, click **Save Changes**.
9. Start the apps again.

### 1.2 Create the VM

1. Download the Debian 13 (trixie) `netinst` ISO for amd64.
2. Go to **Virtual Machines > Add**.
3. Set these values:

   | Field | Value |
   |---|---|
   | Guest OS | Linux |
   | Name | `runner` |
   | Boot Method | UEFI |
   | Start on Boot | On |
   | Virtual CPUs | 4 (2 is the minimum) |
   | Memory Size | 8 GiB (4 GiB is the minimum. Rust builds need more.) |
   | Disk | New zvol on the `fast` pool, 64 GiB, VirtIO |
   | NIC | VirtIO, attached to `br0` |
   | Installation Media | The Debian ISO |

4. Start the VM. Open the VNC display.
5. Install Debian. In the software selection, select only **SSH server** and **standard system utilities**.
6. After the installation, remove the ISO from the VM devices.

### 1.3 Install Docker

Runner v13 needs Docker 25.0 or later. Install Docker from the Docker apt repository, not the Debian `docker.io` package. This gives a known, current version.

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg jq
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
```

### 1.4 Install the runner

These commands come from the Forgejo binary installation guide. They download the latest release and verify its GPG signature.

```sh
export ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
export RUNNER_VERSION=$(curl -s https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq -r .name | cut -c 2-)
export RUNNER_URL="https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-${ARCH}"
wget -O forgejo-runner "${RUNNER_URL}"
wget -O forgejo-runner.asc "${RUNNER_URL}.asc"
gpg --keyserver hkps://keys.openpgp.org --recv EB114F5E6C0DC2BCDD183550A4B61A2DC5923710
gpg --verify forgejo-runner.asc forgejo-runner
sudo install -m 0755 forgejo-runner /usr/local/bin/forgejo-runner
forgejo-runner -v
```

The `gpg --verify` output must say `Good signature from "Forgejo <contact@forgejo.org>"`. If it does not, stop.

Create a dedicated user:

```sh
sudo useradd --create-home --shell /bin/bash runner
sudo usermod -aG docker runner
```

> [!NOTE]
> Membership of the `docker` group is equal to root access on the VM. This is acceptable here because the VM is the security boundary.

### 1.5 Register the runner

Runner v13 uses a new registration flow. The `forgejo-runner register` command is deprecated.

1. In Forgejo, go to `https://git.lan.zanbaldwin.com/admin/actions/runners`.
2. Click **Create new runner**. Name it `vm-runner`.
3. Copy the **UUID** and the **Token**.
4. On the VM, save the token:

   ```sh
   sudo install -d -o runner -g runner -m 0700 /etc/forgejo-runner
   printf '%s' '<token>' | sudo tee /etc/forgejo-runner/token >/dev/null
   sudo chown runner:runner /etc/forgejo-runner/token
   sudo chmod 0600 /etc/forgejo-runner/token
   ```

### 1.6 Configure the runner

Write `/etc/forgejo-runner/config.yaml`. The labels are the same as the current runner in `apps/compose.git.yaml`.

```yaml
log:
  level: 'info'
runner:
  file: '/home/runner/.runner'
  capacity: 1
  timeout: '3h'
  labels:
    - 'ubuntu:docker://git.lan.zanbaldwin.com/actions/runner-images:ubuntu'
    - 'rust:docker://git.lan.zanbaldwin.com/actions/runner-images:rust'
cache:
  enabled: true
  dir: '/home/runner/cache'
container:
  # Mount the VM's Docker socket into each job. Jobs can build and push
  # images without Docker-in-Docker and without `privileged: true`.
  docker_host: 'automount'
  privileged: false
  force_pull: true
server:
  connections:
    forgejo:
      url: 'https://git.lan.zanbaldwin.com/'
      uuid: '<UUID>'
      token_url: 'file:/etc/forgejo-runner/token'
```

The old configuration needed `runner.envs.DOCKER_HOST` and `--add-host` to reach the DinD daemon. With `automount`, jobs use `/var/run/docker.sock`, so remove both.

For a full list of settings, run `forgejo-runner generate-config`.

### 1.7 Start the runner as a service

The runner repository has an official unit file at `contrib/forgejo-runner.service`. The unit below follows it. If they differ, use the official file.

```ini
# /etc/systemd/system/forgejo-runner.service
[Unit]
Description=Forgejo Runner
Documentation=https://forgejo.org/docs/latest/admin/actions/
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/forgejo-runner daemon --config /etc/forgejo-runner/config.yaml
ExecReload=/bin/kill -s HUP $MAINPID
User=runner
WorkingDirectory=/home/runner
Restart=on-failure
RestartSec=10
TimeoutStopSec=infinity

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now forgejo-runner
journalctl -u forgejo-runner -f
```

The runner shows as **Idle** on the Forgejo runners page.

### 1.8 Remove the old runner

1. Start a workflow in a test repository. Make sure that the new runner completes it.
2. On the Forgejo runners page, delete the old runner.
3. In `apps/compose.git.yaml`, remove these items:
   - The `runner` and `dind` services
   - The `runner` network, config and secret
4. Redeploy the `git` app.
5. Delete `/mnt/fast/apps/forgejo/runner` and `/mnt/tank4/secrets/forgejo/runner`.

### Optional hardening

- Put the VM on a separate VLAN. At the moment, a workflow can connect to every service on the LAN. A firewall rule that only allows traffic to the Forgejo host gives better isolation.
- Take a zvol snapshot after the setup. If a workflow damages the VM, roll back to the snapshot.
