# Security Hardening Research

This document summarizes security research and recommendations for hardening a home NAS server, home LAN, and Tailnet based on the current setup.

## Current Setup Summary

| Component | Details |
|-----------|---------|
| **NAS** | TrueNAS SCALE 25.10, running Docker apps via custom YAML |
| **Services** | Immich, Navidrome, Calibre Web, Memos, Next Explorer, Nginx Proxy Manager, Postgres, Valkey |
| **Network** | Zyxel T-56 ISP router, Pi-hole on Raspberry Pi Zero 2W |
| **Remote Access** | Tailscale with subnet routing (192.168.1.0/24) |
| **Devices** | TrueNAS, Pi-hole, Desktop, Laptop, iPhone, reMarkable |

---

## 1. Tailscale Security

### 1.1 Current Vulnerabilities

| Issue | Risk Level | Description |
|-------|------------|-------------|
| **No ACLs configured** | HIGH | Default "allow all" policy means any device on your Tailnet can access any other device on any port |
| **Key expiry disabled on infrastructure** | MEDIUM | TrueNAS and Pi-hole have key expiry disabled; if compromised, they remain connected indefinitely |
| **Not using MagicDNS** | LOW | Using raw IPs instead of MagicDNS names reduces usability but isn't a security issue |
| **Not using Tailscale SSH** | LOW | Could simplify SSH key management and add authentication logging |

### 1.2 Recommended ACL Configuration

Tailscale ACLs follow a **deny-by-default** model. Without explicit rules, no traffic flows. The current "allow all" default is convenient but insecure.

**Recommended ACL strategy for your homelab:**

```json
{
  "acls": [
    // All your devices can access each other (since they're all yours)
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self:*"]
    },
    // All devices can access NAS services via subnet routing
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["192.168.1.0/24:*"]
    },
    // Tagged servers can only be accessed on specific ports
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:nas:22,80,443,2049,2283,3453,4533,5230,8083"]
    }
  ],
  "tagOwners": {
    "tag:nas": ["autogroup:admin"],
    "tag:infra": ["autogroup:admin"]
  },
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["tag:nas"],
      "users": ["truenas_admin", "root"],
      "checkPeriod": "12h"
    }
  ]
}
```

**Key concepts:**
- **Tags**: Label devices by purpose (e.g., `tag:nas`, `tag:infra`) rather than by owner
- **autogroup:member**: All users in your Tailnet
- **Ports**: Restrict access to only necessary ports (SSH:22, HTTP:80, HTTPS:443, NFS:2049, etc.)
- **SSH check mode**: Requires re-authentication every 12 hours for SSH access to critical infrastructure

### 1.3 Key Expiry Recommendations

| Device | Current | Recommended | Reason |
|--------|---------|-------------|--------|
| TrueNAS | Disabled | Keep disabled | Server, needs to stay connected |
| Pi-hole | Disabled | Keep disabled | DNS infrastructure, needs uptime |
| Desktop | 6 months | Keep as-is | Good balance of security/convenience |
| Laptop | 6 months | Keep as-is | Good balance |
| iPhone | 6 months | Keep as-is | Good balance |

**Note**: For servers with key expiry disabled, use **tags** instead of user ownership. Tagged devices have different security properties and can be controlled via ACLs.

---

## 2. SSH Security

### 2.1 Current Vulnerabilities

| Issue | Risk Level | Description |
|-------|------------|-------------|
| **SSH accessible from any IP** | HIGH | TrueNAS SSH is not restricted to LAN/Tailnet IPs |
| **Root login may be enabled** | MEDIUM | Default TrueNAS settings may allow root SSH |
| **Password auth may be enabled** | MEDIUM | Key-only auth is more secure |
| **No fail2ban or rate limiting** | MEDIUM | Brute force attacks possible from LAN |

### 2.2 TrueNAS SSH Hardening

TrueNAS SCALE SSH configuration is managed via the web UI at **System > Services > SSH**.

**Recommended settings:**
- **TCP Port**: 22 (default)
- **Password Login Groups**: Empty (disable password auth)
- **Allow Password Authentication**: OFF (use keys only)
- **Log in as Root with Password**: OFF
- **Allow TCP Port Forwarding**: OFF (unless needed)

**Additional hardening via Auxiliary Parameters:**
```
AllowUsers truenas_admin
PermitRootLogin prohibit-password
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
```

### 2.3 Tailscale SSH (Alternative)

Tailscale SSH can replace traditional SSH authentication entirely:
- Uses Tailscale identity instead of SSH keys
- Centralized access control via ACLs
- Built-in session recording (optional)
- Check mode forces re-authentication

**Limitation**: Tailscale SSH is not available on TrueNAS SCALE because it runs Tailscale in a Docker container, not natively.

### 2.4 Pi-hole / Desktop SSH

Both should have similar hardening:
- Key-only authentication
- Disable root login
- Consider restricting to Tailnet IPs only using firewall rules

---

## 3. TrueNAS Security

### 3.1 Current Vulnerabilities

| Issue | Risk Level | Description |
|-------|------------|-------------|
| **Web UI accessible from any LAN IP** | MEDIUM | Anyone on LAN can attempt to access admin UI |
| **No 2FA on web UI** | MEDIUM | Password-only authentication |
| **Services directly accessible on ports** | LOW | NPM proxies services, but they're also accessible directly |
| **Encrypted dataset for secrets is good** | N/A | This is a positive security measure |

### 3.2 Web UI Security

**Enable Two-Factor Authentication:**
1. Go to **System > Advanced Settings > Global Two Factor Authentication**
2. Enable 2FA for admin accounts
3. Use TOTP app (Google Authenticator, Authy, etc.)

**Restrict Web UI Access (optional, advanced):**
- TrueNAS doesn't have built-in IP restriction for web UI
- Could use iptables/nftables rules, but this is risky on NAS
- Better approach: access only via Tailnet IP (100.x.x.x)

### 3.3 NFS Security

Current NFS shares are LAN-only. Recommendations:
- Use NFSv4 (you're already using `vers=4.1`)
- Restrict exports to specific IP ranges in TrueNAS share settings
- Consider Kerberos authentication for sensitive shares (complex setup)

### 3.4 Docker/Container Security

Your current setup is good:
- Postgres/Valkey not exposed (internal Docker networks only)
- Secrets stored in encrypted dataset
- Secrets passed as Docker secrets, not environment variables

**Additional recommendations:**
- Pin container image versions (you're already doing this)
- Regularly update containers (TrueNAS auto-updates enabled)
- Review container capabilities (`cap_add` should be minimal)

---

## 4. Network Security

### 4.1 Router (Zyxel T-56)

| Issue | Risk Level | Description |
|-------|------------|-------------|
| **Unknown firmware status** | MEDIUM | May have unpatched vulnerabilities |
| **Unknown remote management status** | HIGH | If enabled, router is accessible from internet |
| **WPS disabled** | N/A | Good - WPS is a security risk |
| **UPnP status unknown** | MEDIUM | If enabled, devices can open ports automatically |

**Action items:**
1. Check for firmware updates on Zyxel support site
2. Disable remote management (WAN-side admin access)
3. Verify UPnP is disabled
4. Review port forwarding rules (should be none)
5. Change default admin password if not already done

### 4.2 Pi-hole Security

Pi-hole is a critical infrastructure component:
- **SSH**: Harden same as other devices
- **Web UI**: Use strong password, consider disabling if not needed
- **DNS**: Pi-hole should only accept queries from LAN (default)

### 4.3 Firewall Considerations

**Option A: Router firewall (recommended for simplicity)**
- ISP routers typically block all inbound by default
- Verify no port forwarding rules exist
- Keep outbound unrestricted (needed for updates, etc.)

**Option B: Host-based firewalls (defense in depth)**
- TrueNAS: Not recommended to modify (can break system)
- Pi-hole: `ufw` or `iptables` to restrict SSH to Tailnet
- Desktop: OS firewall to restrict inbound

---

## 5. Service Exposure

### 5.1 Nginx Proxy Manager

**Current situation:**
- All services proxied through NPM with TLS
- Services also directly accessible on ports (e.g., `192.168.1.86:81`)
- Domains publicly resolvable but point to private IPs

**Recommendations:**

1. **Bind services to localhost only** (where possible):
   - Modify Docker compose to bind ports to `127.0.0.1` instead of `0.0.0.0`
   - Example: `127.0.0.1:8083:8083` instead of `8083:8083`
   - NPM can still proxy using Docker network

2. **For NPM itself**:
   - Cannot easily hide port 81 while using host network mode
   - Consider: Switch NPM to bridge network with explicit port mapping
   - Alternative: Use iptables to block direct port 81 access except from localhost

3. **Cloudflare DNS**:
   - Your current setup (public DNS pointing to private IPs) is fine
   - Attackers can see the DNS records but can't reach the IPs
   - Consider: Use split-horizon DNS (different records for internal vs external)

### 5.2 Service Port Exposure Analysis

| Service | Published Port | Recommendation |
|---------|---------------|----------------|
| NPM Admin | 81 | Consider blocking direct access |
| Immich | 2283 | Bind to localhost, proxy only |
| Navidrome | 4533 | Bind to localhost, proxy only |
| Calibre Web | 8083 | Bind to localhost, proxy only |
| Memos | 5230 | Bind to localhost, proxy only |
| Next Explorer | 3453 | Bind to localhost, proxy only |
| Postgres | Not exposed | Good - internal only |
| Valkey | Not exposed | Good - internal only |

---

## 6. Secrets Management

### 6.1 Current State (Good)

- Secrets stored in encrypted dataset `/mnt/tank4/class1/secrets`
- Passed to containers as Docker secrets
- Cloudflare token stored securely

### 6.2 Recommendations

1. **Rotate Cloudflare API token periodically** (annually)
2. **Use scoped API tokens**: Ensure the token has minimal permissions (DNS edit only for your zone)
3. **Audit who has access**: Only your TrueNAS admin account should access the secrets dataset
4. **Backup consideration**: When backing up, exclude or separately encrypt secrets

---

## 7. Backup Strategy

### 7.1 Current Gap

No backups configured. This is a critical security/reliability issue.

### 7.2 ZFS-Based Backup Options

| Method | Description | Complexity |
|--------|-------------|------------|
| **ZFS snapshots** | Local protection against accidental deletion | Low |
| **ZFS send/receive** | Replicate to another ZFS system | Medium |
| **Restic/Rustic to S3** | Encrypted, deduplicated backups to cloud | Medium |
| **TrueCloud Backup** | TrueNAS native integration with Storj | Low |

### 7.3 Recommended Strategy

1. **Periodic ZFS snapshots** (already supported in TrueNAS)
   - Daily snapshots, keep 7 days
   - Weekly snapshots, keep 4 weeks
   - Monthly snapshots, keep 12 months

2. **Offsite backup to S3-compatible storage**
   - Use Restic or Rustic for encrypted, deduplicated backups
   - Target: Backblaze B2, Wasabi, or Storj
   - Include: `/mnt/tank4/class1` (secrets, books, photos)
   - Exclude: Large media that can be re-obtained (optional)

3. **Configuration backup**
   - Export TrueNAS config regularly
   - Store compose files in git (you're already doing this with dotfiles)
   - Document any manual configuration steps

---

## 8. VPN Conflict Resolution

### 8.1 Current Issue

When connecting to NordVPN or Pritunl for work, you lose access to LAN/Pi-hole/Tailnet.

### 8.2 Solution: Split Tunneling

Most VPNs support "split tunneling" - routing only specific traffic through the VPN.

**NordVPN:**
- Use the desktop app's split tunneling feature
- Exclude Tailscale and local network from VPN

**Pritunl:**
- Configure split tunnel on server side (if you have access)
- Or use client-side routing rules

**Alternative: Use Tailscale as VPN**
- If you only need work VPN for specific services
- Consider running a Tailscale exit node at work
- Route work traffic through Tailscale instead

---

## 9. Monitoring and Alerting

### 9.1 What to Monitor

| Component | What to Monitor |
|-----------|-----------------|
| TrueNAS | Failed login attempts, disk health, pool status |
| Tailscale | Device connectivity, unusual access patterns |
| Pi-hole | DNS query patterns, blocked queries |
| Services | Uptime, error logs |

### 9.2 Implementation Options

1. **TrueNAS Alerts**: Configure email notifications for system events
2. **Uptime Kuma**: Self-hosted uptime monitoring (could run as Docker app)
3. **Tailscale audit logs**: Available in admin console (web-based)
4. **Fail2ban**: Monitor and block brute force attempts (on Pi-hole, Desktop)

---

## 10. Priority Summary

### Critical (Do First)
1. Configure Tailscale ACLs
2. Harden SSH on TrueNAS (key-only, no root)
3. Enable 2FA on TrueNAS web UI
4. Verify router remote management is disabled

### High Priority
5. Check router firmware for updates
6. Verify UPnP is disabled on router
7. Set up ZFS snapshot schedule
8. Set up offsite backup to S3

### Medium Priority
9. Bind service ports to localhost (proxy-only access)
10. Harden SSH on Pi-hole
11. Configure split tunneling for work VPN
12. Set up basic monitoring/alerting

### Low Priority
13. Consider Tailscale SSH (if native Tailscale becomes available on TrueNAS)
14. Implement Pi-hole redundancy (secondary DNS)
15. Move Pi-hole to wired ethernet connection

---

## References

- [Tailscale ACLs](https://tailscale.com/kb/1018/acls)
- [Tailscale SSH](https://tailscale.com/kb/1193/tailscale-ssh)
- [Tailscale Key Expiry](https://tailscale.com/kb/1028/key-expiry)
- [Lock Down a Server with UFW](https://tailscale.com/kb/1077/secure-server-ubuntu)
- [TrueNAS SSH Service](https://www.truenas.com/docs/scale/scaletutorials/systemsettings/services/sshservicescale/)
- [TrueNAS Security Recommendations](https://www.truenas.com/docs/solutions/optimizations/security/)
