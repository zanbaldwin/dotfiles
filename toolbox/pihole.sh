#!/usr/bin/env bash
# Assuming "Raspberry Pi Trixie (64bit)"

# WARNING!
# This script includes interactive commands.
# It should be used as a REFERENCE, and NOT be executed directly.

apt-get update
DEBIAN_FRONTEND="noninteractive" apt-get upgrade -y
DEBIAN_FRONTEND="noninteractive" apt-get install -y \
    'apt-transport-https' \
    'coreutils' \
    'curl'

export DEBIAN_VERSION="trixie"
curl -fsSL "https://pkgs.tailscale.com/stable/raspbian/${DEBIAN_VERSION}.noarmor.gpg" | tee '/usr/share/keyrings/tailscale-archive-keyring.gpg' >'/dev/null'
curl -fsSL "https://pkgs.tailscale.com/stable/raspbian/${DEBIAN_VERSION}.tailscale-keyring.list" | tee '/etc/apt/sources.list.d/tailscale.list'
apt-get update

DEBIAN_FRONTEND='noninteractive' apt-get install -y \
    'fail2ban' \
    'tailscale' \
    'ufw' \
    'unbound'

# Raspberry Pi OS already provides zstd zram swap via its rpi-swap framework
# (systemd zram-generator). By default it picks the "zram+file" mechanism, which
# periodically writes idle zram pages back to a swap file on the SD card. Force
# pure zram (no file, no writeback) so nothing ever swaps to the card. This takes
# effect on the next boot, when the rpi-swap-generator reruns.
mkdir -p '/etc/rpi/swap.conf.d'
cat >'/etc/rpi/swap.conf.d/99-zram-only.conf' <<'EOF'
[Main]
Mechanism=zram
EOF
# Remove the leftover writeback swap file the default mechanism left behind.
rm -f '/var/swap'

# zram swap is fast, so bias towards it; one page per swap for lowest latency.
cat >'/etc/sysctl.d/99-zram.conf' <<'EOF'
vm.swappiness = 150
vm.page-cluster = 0
EOF
sysctl --system

# Keep the journal in RAM (/run); nothing written to the SD card. Capped so it
# cannot exhaust RAM on the 512M device. Logs do not survive a reboot.
mkdir -p '/etc/systemd/journald.conf.d'
cat >'/etc/systemd/journald.conf.d/volatile.conf' <<'EOF'
[Journal]
Storage=volatile
RuntimeMaxUse=32M
EOF
systemctl restart 'systemd-journald'

curl -fsSL 'https://install.pi-hole.net' -o '/tmp/pihole.sh'
export INSTALLER_CHECKSUM="84d278d104a30186f6924889c420d6f5c2bcc74ac525481bc65f454d202ebc84"
echo "${INSTALLER_CHECKSUM} /tmp/pihole.sh" | tee '/tmp/pihole.sig'
if ! sha256sum --check '/tmp/pihole.sig' --strict --status; then
    echo >&2 'Installer has changed; failed checksum.'
    exit 1
fi

# Keep the ban database in RAM. Trade-off: active bans are lost on restart.
cat >'/etc/fail2ban/fail2ban.local' <<'EOF'
[Definition]
dbfile = :memory:
EOF
systemctl enable --now 'fail2ban'

cat >'/etc/unbound/unbound.conf.d/pihole.conf' <<EOF
server:
    # Log minimally to syslog (RAM-backed journald), not a dedicated SD file.
    # Raise verbosity to 1 temporarily when debugging resolution.
    verbosity: 0
    use-syslog: yes
    log-queries: no
    log-replies: no
    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes
    # May be set to no if you don't have IPv6 connectivity
    do-ip6: yes
    # You want to leave this to no unless you have *native* IPv6.
    prefer-ip6: no
    # Trust glue only if it is within the server's authority
    harden-glue: yes
    # Require DNSSEC data for trust-anchored zones, if such data is absent, the zone becomes BOGUS
    harden-dnssec-stripped: yes
    # Don't use Capitalization randomization as it known to cause DNSSEC issues sometimes
    use-caps-for-id: no
    # Reduce EDNS reassembly buffer size.
    edns-buffer-size: 1232
    # Perform prefetching of close to expired message cache entries
    # This only applies to domains that have been frequently queried
    prefetch: yes
    # One thread should be sufficient.
    num-threads: 1
    # Ensure kernel buffer is large enough to not lose messages in traffic spikes
    so-rcvbuf: 1m
    # Ensure privacy of local IP ranges
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10
    # Ensure no reverse queries to non-public IP ranges (RFC6303 4.2)
    private-address: 192.0.2.0/24
    private-address: 198.51.100.0/24
    private-address: 203.0.113.0/24
    private-address: 255.255.255.255/32
    private-address: 2001:db8::/32
    # This publicly-hosted zone intentionally resolves to private IPs; exempt it
    # from the rebind protection above (stripping breaks DNSSEC validation).
    private-domain: "lan.zanbaldwin.com"
    # Increase TCP connection limits (default 10 is too low for Pi-hole FTL)
    incoming-num-tcp: 50
    outgoing-num-tcp: 20
    # Constrain memory usage for low-RAM devices
    msg-cache-size: 16m
    rrset-cache-size: 32m
    key-cache-size: 16m
    # Disable subnetcache module (not needed for a local resolver, saves memory)
    module-config: "validator iterator"
forward-zone:
    # Forward all Tailscale domains to their MagicDNS
    name: 'ts.net.'
    forward-addr: '100.100.100.100'
EOF
systemctl disable --now 'unbound-resolvconf.service'
systemctl restart 'unbound'
systemctl enable 'logrotate.timer'

# cat >'/etc/pihole/setupVars.conf' <<EOF
# WEBPASSWORD=<some_double_sha256_hash>
# IPV4_ADDRESS=192.168.1.74/24
# QUERY_LOGGING=true
# INSTALL_WEB_INTERFACE=true
# LIGHTTPD_ENABLED=true
# INSTALL_WEB_SERVER=true
# DNSMASQ_LISTENING=single
# PIHOLE_DNS_1=127.0.0.1#5335
# DNS_FQDN_REQUIRED=true
# DNS_BOGUS_PRIV=true
# # DNS is already validated by Unbound, double-validation is redundant.
# DNSSEC=false
# TEMPERATUREUNIT=C
# WEBUIBOXEDLAYOUT=traditional
# API_QUERY_LOG_SHOW=all
# API_PRIVACY_MODE=false
# BLOCKING_ENABLED=true
# EOF
bash '/tmp/pihole.sh'

# The FTL long-term database (pihole-FTL.db) is the main ongoing SD write source.
# Batch query-log writes to every 10 min instead of 60s, and cap history at 30
# days. Trade-off: up to ~10 min of query history lost on an unclean power-off.
pihole-FTL --config database.DBinterval 600
pihole-FTL --config database.maxDBdays 30

# The following command is interactive...
tailscale up --accept-dns=false

# Local Network
ufw allow from '192.168.0.0/16' to any port 443
ufw allow from '192.168.0.0/16' to any port 53
ufw allow from '192.168.0.0/16' to any port 22
# Tailscale
ufw allow from '100.64.0.0/10' to any port 443
ufw allow from '100.64.0.0/10' to any port 53
ufw allow from '100.64.0.0/10' to any port 22
systemctl enable --now 'ufw'
ufw enable

# Reduce metadata/journal writes on the SD card. Find the real PARTUUIDs with:
#   lsblk -o NAME,PARTUUID,FSTYPE,MOUNTPOINT
# then edit '/etc/fstab' so the mounts read (do NOT put ext4 opts on vfat):
#   PARTUUID=xxxxxxxx-02  /               ext4  defaults,noatime,commit=120  0 1
#   PARTUUID=xxxxxxxx-01  /boot/firmware  vfat  defaults,noatime,flush       0 2
# noatime is free and high-value; commit=120 batches ext4 flushes (default 5s),
# risking up to ~2 min of unflushed data on a crash. Apply with: mount -o remount /

# Debian Trixie already mounts /tmp as tmpfs via the tmp.mount unit; verify with
# 'findmnt /tmp' (only run "systemctl enable --now tmp.mount" if it is inactive).
