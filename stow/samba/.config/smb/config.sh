# Shared configuration for smb-mount / smb-pkexec.
#
# This file is *sourced* by those scripts (running as both the user and, via
# pkexec, root) -- it is not executed on its own. Keep it to plain variable
# assignments; do not put commands here.
#
# Credentials are NOT kept here. Put them in ~/.config/smb/credentials (mode
# 0600) in mount.cifs format:
#   username=zan
#   password=...

SERVER='nas.lan.zanbaldwin.com'     # SMB server hostname
SERVER_PORT='445'                   # TCP port smb-mount probes to detect on-LAN
MOUNT_OPTS='rw,vers=3.1.1,seal,mfsymlinks,nobrl'  # options passed to mount -o (uid/gid/credentials are appended)
CONTAINER='network-tailscale-1'     # Tailscale container to bring up when off-LAN
HEALTH_TIMEOUT='30'                 # seconds to wait for it to report healthy

# Mountpoint (under the user's home) -> SMB share name on the server.
# Suffixed with -SMB while running side-by-side with the NFS mounts.
declare -A SHARES=(
    ['Drive']='drive'
    ['Music']='music'
    ['Books']='books'
)
