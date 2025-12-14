# Security Hardening Implementation Plan

This document provides step-by-step instructions for implementing the security recommendations from `RESEARCH.md`.

---

## Phase 1: Critical Security (Week 1)

### 1.1 Configure Tailscale ACLs

**Time estimate**: 30 minutes  
**Risk**: Low (can be reverted instantly)  
**Requires**: Tailscale admin console access

1. Go to [Tailscale Admin Console > Access Controls](https://login.tailscale.com/admin/acls)

2. Replace the default ACL with the following (adjust as needed):

```json
{
  // Define tag owners - you (as admin) can apply these tags to devices
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:infra": ["autogroup:admin"]
  },

  // Access control rules
  "acls": [
    // All your devices can communicate with each other
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:member:*"]
    },
    // All devices can access the home subnet via TrueNAS subnet router
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["192.168.1.0/24:*"]
    }
  ],

  // Tests to verify ACLs work as expected
  "tests": [
    {
      "src": "autogroup:member",
      "accept": ["192.168.1.86:443", "192.168.1.86:22"]
    }
  ]
}
```

3. Click **Save** - changes take effect within seconds

4. **Test immediately**:
   - From your laptop (via Tailnet), try to access `https://photos.lan.zanbaldwin.com`
   - Try SSH to TrueNAS: `ssh truenas_admin@192.168.1.86`
   - If anything breaks, revert to default ACL

**Optional enhancement** - Add tags to your servers:
1. Go to [Machines](https://login.tailscale.com/admin/machines)
2. Click the menu (⋯) for TrueNAS → Edit ACL tags → Add `tag:server`
3. Repeat for Pi-hole with `tag:infra`

---

### 1.2 Harden TrueNAS SSH

**Time estimate**: 15 minutes  
**Risk**: Medium (could lock yourself out - have TeamViewer ready)  
**Requires**: TrueNAS web UI access, TeamViewer backup access

#### Step 1: Verify your SSH key is configured

```bash
# On your laptop, check if you have an SSH key
ls -la ~/.ssh/id_*.pub

# If you don't have one, generate it:
ssh-keygen -t ed25519 -C "your_email@example.com"
```

#### Step 2: Ensure your key is in TrueNAS authorized_keys

1. SSH to TrueNAS: `ssh truenas_admin@192.168.1.86`
2. Verify key is present: `cat ~/.ssh/authorized_keys`
3. If not present, add it via TrueNAS UI:
   - Go to **Credentials > Users**
   - Edit `truenas_admin`
   - Paste your public key in **SSH Public Key**

#### Step 3: Harden SSH settings

1. Go to **System > Services > SSH** (click the pencil icon)

2. Configure **Basic Settings**:
   - **TCP Port**: `22` (keep default)
   - **Password Login Groups**: *Leave empty*
   - **Allow Password Authentication**: **OFF**
   - **Allow Kerberos Authentication**: OFF
   - **Allow TCP Port Forwarding**: OFF

3. Click **Advanced Settings** and add **Auxiliary Parameters**:
   ```
   PermitRootLogin prohibit-password
   MaxAuthTries 3
   LoginGraceTime 30
   ClientAliveInterval 300
   ClientAliveCountMax 2
   ```

4. Click **Save**

#### Step 4: Test BEFORE closing your current session

```bash
# In a NEW terminal window (keep old one open!)
ssh truenas_admin@192.168.1.86

# If it works with key auth, you're good
# If it fails, use the old terminal or TeamViewer to revert
```

---

### 1.3 Enable TrueNAS 2FA

**Time estimate**: 10 minutes  
**Risk**: Low (can be disabled if locked out via console)  
**Requires**: TrueNAS web UI, TOTP app (Bitwarden, Google Authenticator, etc.)

1. Log into TrueNAS web UI

2. Go to **System > Advanced Settings**

3. Find **Global Two Factor Authentication** section

4. Click **Configure** and enable:
   - **Enable Two-Factor Authentication for SSH**: Optional (your choice)
   - **Global 2FA**: Enable

5. Scan the QR code with your authenticator app

6. Store the recovery codes in Bitwarden

7. **Test**: Log out and log back in - you should be prompted for 2FA code

---

### 1.4 Check Router Security

**Time estimate**: 20 minutes  
**Risk**: Low  
**Requires**: Router admin access (usually 192.168.1.1)

#### Step 1: Log into router admin panel

1. Open browser to `http://192.168.1.1` (or your router's IP)
2. Log in with admin credentials

#### Step 2: Check remote management

Look for settings named:
- "Remote Management"
- "Remote Access"
- "WAN Access"
- "External Management"

**Disable all of these** - you should only manage the router from LAN.

#### Step 3: Check UPnP

Look for "UPnP" or "Universal Plug and Play" settings.

**Disable UPnP** - it allows devices to automatically open ports, which is a security risk.

#### Step 4: Check port forwarding

Look for "Port Forwarding", "NAT", or "Virtual Servers".

**Verify no rules exist** - you shouldn't have any ports forwarded since you use Tailscale.

#### Step 5: Check firmware

1. Note current version: `V5.70(ACEA.0)T56C_b10_0410`
2. Check Zyxel support site for T-56 updates
3. If update available, download and apply (follow router instructions)

#### Step 6: Change admin password (if default)

If you haven't changed the router admin password from the ISP default, change it now.

---

## Phase 2: High Priority (Week 2)

### 2.1 Set Up ZFS Snapshots

**Time estimate**: 15 minutes  
**Risk**: None  
**Requires**: TrueNAS web UI

1. Go to **Data Protection > Periodic Snapshot Tasks**

2. Click **Add** and create these snapshot schedules:

**Daily snapshots (tank4/class1)**:
- Dataset: `tank4/class1`
- Recursive: Yes
- Snapshot Lifetime: 7 days
- Schedule: Daily at 2:00 AM
- Naming Schema: `auto-%Y-%m-%d_%H-%M`

**Weekly snapshots (tank4/class1)**:
- Dataset: `tank4/class1`
- Recursive: Yes
- Snapshot Lifetime: 4 weeks
- Schedule: Weekly, Sunday at 3:00 AM

**Monthly snapshots (tank4)**:
- Dataset: `tank4`
- Recursive: Yes
- Snapshot Lifetime: 12 months
- Schedule: Monthly, 1st day at 4:00 AM

3. Click **Save** for each task

---

### 2.2 Set Up Offsite Backup (Backblaze B2)

**Time estimate**: 1-2 hours (initial setup + first backup)  
**Risk**: Low  
**Requires**: Backblaze account, TrueNAS web UI

#### Step 1: Create Backblaze B2 account and bucket

1. Sign up at [backblaze.com](https://www.backblaze.com/b2/sign-up.html)
2. Create a bucket:
   - Name: `truenas-backup-[random]` (must be globally unique)
   - Files: Private
   - Encryption: Enable server-side encryption
   - Object Lock: Enable (for ransomware protection)
3. Create application key:
   - Key Name: `truenas-backup`
   - Allow access to bucket: Your backup bucket only
   - Type: Read and Write
   - **Save the keyID and applicationKey** - shown only once!

#### Step 2: Add cloud credentials in TrueNAS

1. Go to **Credentials > Backup Credentials > Cloud Credentials**
2. Click **Add**
3. Configure:
   - Name: `Backblaze B2`
   - Provider: `Backblaze B2`
   - Key ID: (paste from Backblaze)
   - Application Key: (paste from Backblaze)
4. Click **Verify Credential** then **Save**

#### Step 3: Create cloud sync task

1. Go to **Data Protection > Cloud Sync Tasks**
2. Click **Add**
3. Configure:
   - Description: `Backup class1 to B2`
   - Direction: PUSH
   - Transfer Mode: SYNC
   - Credential: Backblaze B2
   - Bucket: (select your bucket)
   - Folder: `/class1`
   - Directory/Files: `/mnt/tank4/class1`
   - Schedule: Daily at 1:00 AM
   - Enabled: Yes

4. Under **Advanced Options**:
   - Transfers: 4
   - Bandwidth Limit: (optional, e.g., `10M` for 10 MB/s to not saturate upload)

5. Click **Save**

6. Run the task manually once to verify it works:
   - Click the play button (▶) on the task
   - Monitor progress in **Jobs**

---

### 2.3 Harden Pi-hole SSH

**Time estimate**: 20 minutes  
**Risk**: Medium (could lock yourself out)  
**Requires**: SSH access to Pi-hole

```bash
# SSH to Pi-hole
ssh pi@192.168.1.x  # Replace with Pi-hole IP

# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Edit SSH config
sudo nano /etc/ssh/sshd_config
```

Add/modify these settings:
```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
```

Test and apply:
```bash
# Test config
sudo sshd -t

# If no errors, restart SSH
sudo systemctl restart sshd

# TEST IN NEW TERMINAL before closing current session!
```

---

## Phase 3: Medium Priority (Week 3-4)

### 3.1 Restrict Service Port Access

**Goal**: Make services accessible only through NPM proxy, not directly via IP:port.

**Time estimate**: 30 minutes per service  
**Risk**: Medium (could break service access)  
**Requires**: TrueNAS app management

#### Option A: Bind to localhost (Recommended)

Modify your compose files to bind services to `127.0.0.1` instead of `0.0.0.0`.

**Example for Immich** (`compose.photos.yaml`):
```yaml
# Change this:
ports:
  - target: 2283
    published: 2283
    protocol: 'tcp'

# To this:
ports:
  - target: 2283
    published: 2283
    host_ip: '127.0.0.1'
    protocol: 'tcp'
```

**Caveat**: NPM uses `network_mode: host`, so it can still access localhost ports.

**For each service**:
1. Update the compose file
2. Redeploy the app in TrueNAS
3. Test that proxy access still works: `https://photos.lan.zanbaldwin.com`
4. Verify direct access is blocked: `http://192.168.1.86:2283` should fail

#### Option B: Firewall rules (Alternative)

If binding to localhost doesn't work for your setup, use iptables to block direct access:

```bash
# On TrueNAS, create a script to block direct service port access
# Allow access from localhost and Tailnet, block from LAN

# Example for port 2283 (Immich)
iptables -A INPUT -p tcp --dport 2283 -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -p tcp --dport 2283 -s 100.64.0.0/10 -j ACCEPT  # Tailnet
iptables -A INPUT -p tcp --dport 2283 -j DROP
```

**Note**: iptables rules on TrueNAS are not persistent and not officially supported. Use with caution.

---

### 3.2 Configure Split Tunneling for Work VPN

**Time estimate**: 15 minutes  
**Risk**: Low

#### NordVPN Split Tunneling

1. Open NordVPN app
2. Go to **Settings > Split Tunneling**
3. Enable split tunneling
4. Add exclusions:
   - Tailscale application
   - IP ranges: `100.64.0.0/10` (Tailnet), `192.168.1.0/24` (home LAN)

#### Pritunl

Pritunl split tunneling is configured server-side. If you don't control the server:

1. Check if your Pritunl profile has "split tunnel" routes
2. Ask your IT admin to configure split tunneling
3. Alternative: Run Pritunl in a VM or container to isolate it

---

### 3.3 Set Up Basic Monitoring

**Time estimate**: 30 minutes  
**Risk**: None

#### Option A: TrueNAS Email Alerts

1. Go to **System > General > Email**
2. Configure SMTP settings (e.g., Gmail, SendGrid, or your email provider)
3. Go to **Alerts > Alert Settings**
4. Configure which alerts to receive via email

#### Option B: Uptime Kuma (Self-hosted)

Add to your TrueNAS apps:

```yaml
name: 'monitoring'
services:
  uptime-kuma:
    image: 'louislam/uptime-kuma:1'
    restart: 'unless-stopped'
    ports:
      - target: 3001
        published: 3001
        protocol: 'tcp'
    volumes:
      - type: 'bind'
        source: '/mnt/fast/apps/uptime-kuma'
        target: '/app/data'
        read_only: false
```

Then add monitors for:
- TrueNAS web UI
- Each proxied service
- Pi-hole DNS
- External connectivity (e.g., ping 1.1.1.1)

---

## Phase 4: Optional Improvements (Future)

### 4.1 Pi-hole Redundancy

Set up a secondary Pi-hole or use Unbound as backup DNS.

### 4.2 Move Pi-hole to Ethernet

For reliability, connect Pi-hole via ethernet instead of WiFi.

### 4.3 Log Aggregation

Set up centralized logging with Loki + Grafana or similar.

### 4.4 Intrusion Detection

Consider running CrowdSec or similar on your network.

---

## Rollback Procedures

### Tailscale ACLs
1. Go to [Access Controls](https://login.tailscale.com/admin/acls)
2. Click **Reset to default** or paste previous config

### TrueNAS SSH
1. Use TeamViewer to access TrueNAS console
2. Go to **System > Services > SSH**
3. Enable password authentication temporarily
4. SSH in and fix the issue
5. Re-disable password auth

### TrueNAS 2FA
1. Use recovery code to log in
2. Go to **System > Advanced Settings**
3. Disable 2FA

### Pi-hole SSH
1. Connect keyboard/monitor directly to Pi-hole
2. Log in locally
3. Restore backup: `sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config`
4. Restart SSH: `sudo systemctl restart sshd`

---

## Maintenance Schedule

| Task | Frequency | How |
|------|-----------|-----|
| Check TrueNAS alerts | Weekly | Web UI or email |
| Review Tailscale devices | Monthly | Admin console |
| Rotate Cloudflare API token | Annually | Cloudflare dashboard |
| Test backup restoration | Quarterly | Restore random files from B2 |
| Check for TrueNAS updates | Monthly | Web UI notifications |
| Review router settings | Quarterly | Router admin panel |
| Audit service accounts | Annually | Check all service passwords |

---

## Checklist

### Phase 1: Critical
- [ ] Configure Tailscale ACLs
- [ ] Harden TrueNAS SSH
- [ ] Enable TrueNAS 2FA
- [ ] Disable router remote management
- [ ] Verify UPnP is disabled
- [ ] Check for router firmware updates

### Phase 2: High Priority
- [ ] Set up ZFS snapshot schedules
- [ ] Set up Backblaze B2 backup
- [ ] Harden Pi-hole SSH
- [ ] Export TrueNAS config backup

### Phase 3: Medium Priority
- [ ] Restrict service ports to localhost
- [ ] Configure work VPN split tunneling
- [ ] Set up email alerts
- [ ] (Optional) Deploy Uptime Kuma

### Phase 4: Future
- [ ] Pi-hole redundancy
- [ ] Move Pi-hole to ethernet
- [ ] Centralized logging
- [ ] Intrusion detection
