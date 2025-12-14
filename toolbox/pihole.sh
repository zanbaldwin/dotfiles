#!/usr/bin/env bash
# Assuming "Raspberry Pi Trixie (64bit)"

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

DEBIAN_FRONTEND='noninteractive' apt-get install -y
    'fail2ban' \
    'tailscale' \
    'ufw' \
    'unbound'

curl -fsSL 'https://install.pi-hole.net' -o '/tmp/pihole.sh'
export INSTALLER_CHECKSUM="84d278d104a30186f6924889c420d6f5c2bcc74ac525481bc65f454d202ebc84"
echo "${INSTALLER_CHECKSUM} /tmp/pihole.sh" | tee '/tmp/pihole.sig'
if ! sha256sum --check '/tmp/pihole.sig' --strict --status; then
    echo >&2 'Installer has changed; failed checksum.'
    exit 1
fi

systemctl enable --now 'fail2ban'

mkdir -p '/var/log/unbound'
chown -R 'unbound:unbound' '/var/log/unbound'
cat >'/etc/unbound/unbound.conf.d/pihole.conf' <<EOF
server:
    # If no logfile is specified, syslog is used
    logfile: '/var/log/unbound/unbound.log'
    verbosity: 1
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
forward-zone:
    # Forward all Tailscale domains to their MagicDNS
    name: 'ts.net.'
    forward-addr: '100.100.100.100'
EOF
cat >'/etc/logrotate.d/unbound' <<EOF
/var/log/unbound/unbound.log {
    weekly
    size 100M
    rotate 12
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    create 0644 unbound unbound
    postrotate
        /usr/sbin/unbound-control log_reopen >/dev/null 2>&1 || true
    endscript
}
EOF
systemctl disable --now 'unbound-resolvconf.service'
systemctl restart 'unbound'
systemctl restart 'logrotate'

# cat >'/etc/pihole/setupVars.conf' <<EOF
# WEBPASSWORD=<some_double_sha256_hash>
# IPV4_ADDRESS=192.168.1.76/24
# QUERY_LOGGING=true
# INSTALL_WEB_INTERFACE=true
# LIGHTTPD_ENABLED=true
# INSTALL_WEB_SERVER=true
# DNSMASQ_LISTENING=single
# PIHOLE_DNS_1=127.0.0.1#5335
# DNS_FQDN_REQUIRED=true
# DNS_BOGUS_PRIV=true
# DNSSEC=true
# TEMPERATUREUNIT=C
# WEBUIBOXEDLAYOUT=traditional
# API_QUERY_LOG_SHOW=all
# API_PRIVACY_MODE=false
# BLOCKING_ENABLED=true
# EOF
bash '/tmp/pihole.sh'

# The following command is interactive...
tailscale up --accept-dns=false

# Local Network
ufw allow from '192.168.0.0/16' to any port 443
ufw allow from '192.168.0.0/16' to any port 22
# Tailscale
ufw allow from '100.64.0.0/10' to any port 443
ufw allow from '100.64.0.0/10' to any port 22
systemctl enable --now 'ufw'
ufw enable
