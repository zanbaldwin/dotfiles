# Shared configuration for nfs-mount / nfs-mount-helper.
#
# This file is *sourced* by those scripts (running as both the user and, via
# pkexec, root) -- it is not executed on its own. Keep it to plain variable
# assignments; do not put commands here.

SERVER='nas.lan.zanbaldwin.com'     # NFS server hostname
SERVER_PORT='2049'                  # TCP port nfs-mount probes to detect on-LAN
MOUNT_OPTS='rw,vers=4.1,proto=tcp'  # options passed to mount -o
CONTAINER='network-tailscale-1'     # Tailscale container to bring up when off-LAN
HEALTH_TIMEOUT='30'                 # seconds to wait for it to report healthy

# Share name (mountpoint under the user's home) -> NFS export on the server.
declare -A SHARES=(
    ['Drive']='/mnt/tank4/drive'
    ['Music']='/mnt/tank4/music'
    ['Books']='/mnt/tank4/books'
)
