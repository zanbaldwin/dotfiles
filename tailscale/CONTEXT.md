# Round 1

## Network & Infrastructure

1. TrueNAS version: Are you running TrueNAS SCALE or CORE?

> I am using TrueNAS SCALE 25.10

2. Other services on TrueNAS: Besides Immich, what other services are exposed (SMB shares, SSH, web UI, other Docker apps)?

> My TrueNAS server is hosting NFS shares, has SSH access enabled, and is running the following services (using custom YAML config instead of TrueNAS apps): Calibre Web, Postgres, Valkey, Next Explorer, Navidrome, Nginx Proxy Manager, Memos, Immich, and Tailscale. Additionally, I am evaluating Jellyfin and Plex.

3. Router/Firewall: What router are you using at home? Does it have firewall capabilities? Any current firewall rules configured?

> I am using the default router provided by my ISP. It is a Zyxel T-56, and I have not altered the settings except to: give some devices a permanent IP address, and change the default advertised DNS address.

4. Port forwarding: Are any ports forwarded from your home router to the TrueNAS server or other devices?

> No, I am not using port forwarding.

## Access & Authentication

5. SSH access: Is SSH enabled on TrueNAS? How do you currently authenticate (password, keys)?

> Yes, SSH access is enabled for the default `truenas_admin` (with only my public key authorized).

6. TrueNAS Web UI: Is it accessible only on LAN or also via Tailnet? What authentication method?

> The TrueNAS web UI is accessible via both LAN and Tailnet, using password authentication (saved in Bitwarden).

7. Tailscale ACLs: Have you configured any Access Control Lists in your Tailnet admin console, or is it default (allow all)?

> I have not configured any ACLs because I do not understand them yet.

8. Tailscale features: Are you using any of these: MagicDNS, Tailscale SSH, HTTPS certificates, or Funnel?

> I am not using the SSH, HTTPS certificates or Funnel features of Tailscale, and I am unsure if I am using MagicDNS (I do not use `ts.net` or `100.x.x.x` to connect anything, only `192.168.1.x` IPs). In regards to HTTPS certificates, I am using Nginx Proxy Manager to use Let's Encrypt to issue certs for my own personal domain using DNS-01.

## Users & Devices

9. Tailnet devices: How many devices are on your Tailnet? Are they all yours, or do you share with family/others?

> I have 5 devices connected to my Tailnet: TrueNAS, Pihole, Desktop, Laptop, and Phone. They are all devices owned and controlled by me.

10. User accounts: Multiple users on TrueNAS? How are they managed?

> I have two accounts on the TrueNAS: the default `truenas_admin` account, and another account `zan` that I created to have the same UID as the accounts on my desktop and laptop so that NFS shares wouldn't have permission issues. I don't use the `zan` account except to own certain datasets.

## Exposure & Remote Access

11. Public exposure: Besides Tailscale, is anything on your home network accessible from the public internet (e.g., via Cloudflare Tunnel, port forwarding)?

> No, as far as I am aware, nothing is exposed to the public internet. I intend to keep it that way. If I want a service/website exposed to the public internet, I will using a hosting provider such as Hetzner to avoid risking my LAN.

12. VPN alternatives: Do you use any other VPN or remote access solution besides Tailscale?

> Yes, I occasionally use NordVPN or Pritunl for work. Whenever I connect to these VPNs on my laptop, I lose access to my LAN/Pihole/etc and don't know how to make them work with each other.

## Priorities

13. Primary concerns: What are you most worried about? (e.g., unauthorized access, data theft, ransomware, family members accessing things they shouldn't)

> My primary concern is that I lack the knowledge to know if my home network is secure or not; that I'll get hacked and become part of a botnet; that certain data (such as API keys, etc) will get scraped, or my data remotely wiped.

14. Usability tolerance: How much friction are you willing to accept for security? (e.g., requiring 2FA everywhere, complex SSH key management)

> I'm willing to accept some friction (eg, requiring 2FA for logging into TrueNAS administration) but not everywhere (eg, requiring 2FA everytime I boot my laptop to connect to NFS).

# Round 2

## TrueNAS & Services

1. Nginx Proxy Manager: Which services are you proxying through it? Are all proxied services only accessible on LAN/Tailnet, or are any subdomains publicly resolvable and accessible?

> I proxy almost everything through NPM in order to add TLS certificates to all my services. All domains/subdomains are publicly resolvable, as I use Cloudflare for mapping domains to IP addresses. However those all resolve to `192.168.1.x` IPs that are not accessible from the public internet.

2. Postgres/Valkey: Are these only used internally by your other services (Immich, Memos, etc.), or do you connect to them directly from other machines?

> Correct, Postgres and Valkey are internal and not exposed outside of my NAS server, as their ports are not exposed. Additionally, they have their own Docker networks, so they aren't even available to services on the same machine that don't need them.

3. NFS shares: Are these mounted only on your desktop/laptop on the LAN, or also accessed remotely via Tailnet?

> At the moment, my NFS shares are only available on my desktop on my LAN. Theoretically they should be available remotely over Tailnet, but I have not tested that (laptop OS is EOL and needs updating before it can connect, but I have not gotten around to that chore).

## Network

4. Pihole: Is this running on a separate device (Raspberry Pi?) or on TrueNAS? Is it your network-wide DNS server (i.e., all LAN devices use it)?

> Yes, the Pi-hole is running on a Raspberry Pi Zero 2W. It is connected over Wifi but I have plans to move it to an ethernet connection. I have configured my router to advertise its IP as the DNS server for the entire LAN.

5. ISP Router admin access: Do you have full admin access to the Zyxel router? Can you configure its firewall, disable UPnP, check for open ports, etc.?

> Yes, I have full admin access to the Zyxel router. I have not configured its firewall or checked for open ports, but have disabled WPS (which I believe automatically disabled UPnP).

6. Other devices on LAN: Besides TrueNAS, desktop, and the Pihole device, are there other devices on your home network (smart TVs, IoT devices, other computers)?

> I have up to 6 devices connected to my LAN at any one time: TrueNAS, Pihole, Desktop, Laptop, iPhone, reMarkable Paper Pro. I do not currently own any other devices.

## Credentials & Secrets

7. API keys/secrets for services: How are these currently stored and passed to your Docker containers? Environment variables in compose files? .env files? TrueNAS secrets?

> I currently store secrets as individual files in an encrypted dataset `/mnt/tank4/class1/secrets` and they are passed into containers as Docker secrets. Because I deploy my services as custom YAML TrueNAS apps, I am unable to provide separate `.env` files.

8. Cloudflare API token: For DNS-01 challenges, you must have a Cloudflare token somewhere. Where is this stored?

> My Cloudflare token is stored at `/mnt/tank4/class1/secrets/cloudflare`, however I do believe that Nginx Proxy Manager stores a copy for itself in its own configuration directory.

## Current Security Measures

9. Automatic updates: Is TrueNAS configured for automatic updates? What about the Docker containers?

> Yes, TrueNAS is configured for automatic updates for both itself and containers ("apps"), though this server hasn't been running long enough for any updates to be available so it is untested.

10. Backups: Do you have backups of your TrueNAS configuration and important data? Where are they stored (on the same NAS, offsite)?

> No, I currently do not have backups configured though it is something on my todo list. Specifically, I plan on making incremental backups of `/mnt/tank4/class1` to some kind of S3 storage but am unsure of the best way to do that. I was hoping there was something with ZFS that I could use but haven't done enough research.

# Round 3

## SSH & Access

1. SSH on TrueNAS: Is SSH accessible from any IP, or have you restricted it to specific subnets (e.g., only LAN or Tailnet IPs)?

> I believe SSH is accessible from any IP, and I have not changed any of the default settings. The current settings are whatever the TrueNAS defaults are.

2. SSH on other devices: Do you have SSH enabled on the Pihole (Raspberry Pi) or any other devices? If so, how is authentication configured?

> Yes, SSH is enabled on the Pi-hole and my desktop computer. They both also use the default settings for OpenSSH Server.

## Router & Network

3. Router firmware: Do you know if your Zyxel T-56 is running the latest firmware? Does it have any known vulnerabilities you're aware of?

> The router declares it's firmware version as `V5.70(ACEA.0)T56C_b10_0410` and I don't know anything about that.

4. Remote management: Is remote management (WAN-side admin access) disabled on your router?

> I do not know how to check if the router has remote management enabled or not.

## Services

5. Nginx Proxy Manager admin UI: Is the NPM admin interface (typically port 81) also proxied with TLS, or is it accessed directly via IP:port?

> Yes, the NPM admin UI is also proxied with TLS (`https://proxy.lan.zanbaldwin.com` -> `http://192.168.1.86:81`). Unfortunately, it is also accessible directly through `http://192.168.1.86:81/` and I don't know how to change that (same with other proxied apps/services).

6. Service authentication: Do your self-hosted services (Immich, Navidrome, Calibre Web, Memos, etc.) have their own authentication, or are any of them "open" behind the proxy?

> All my services have their own authentication enabled and are not "open". I have specifically set manual user accounts for all of them (saved to Bitwarden) as I do not want to rely on a third-party SSO service that may or may not be available in the future.

## Tailscale

7. Tailscale account: Is your Tailscale account using SSO (Google, Microsoft, etc.) or email/password? Is 2FA enabled on that identity provider?

> My Tailscale account is using SSO (Google) because they no longer provide email/password login (see <https://tailscale.com/kb/1013/sso-providers#signing-up-with-an-email-address>). MFA is enabled for that Google account (both TOTP and Passkey).

8. Key expiry: Have you disabled key expiry on any of your Tailscale nodes, or are they all using the default expiry?

> iPhone, Laptop and Desktop have key expiry enabled (6 months). Pi-hole and TrueNAS have key expiry disabled. All auth keys generated are restricted to single-use.

---

Additional context: you now have access to the Compose configuration for the apps hosted on TrueNAS in the `apps/` directory, including a user reference and a screenshot of the proxy hosts configured in Nginx Proxy Manager.
