# Datasets

```
TrueNAS
 ├─ pool(fast)
 │   ├─ vms
 │   └─ apps
 │       ├─ calibre
 │       │   ├─ server
 │       │   └─ web
 │       ├─ postgres
 │       ├─ immich
 │       ├─ navidrome
 │       ├─ proxy
 │       │   ├─ config
 │       │   └─ certs
 │       ├─ tailscale
 │       └─ backrest
 └─ pool(tank4)
     ├─ backups
     ├─ books
     ├─ code
     ├─ drive
     ├─ music
     ├─ photos
     └─ secrets
```

# Port Mappings

| Service                | Port   | Proxy Domain                 |
|------------------------|--------|------------------------------|
| Backrest               | `9898` | `backup.lan.zanbaldwin.com`  |
| Calibre Web            | `8083` | `books.lan.zanbaldwin.com`   |
| Container Updates      | `8321` | `cup.nas.lan.zanbaldwin.com` |
| Navidrome              | `4533` | `music.lan.zanbaldwin.com`   |
| Immich                 | `2283` | `photos.lan.zanbaldwin.com`  |
| Nginx Proxy Manager    | `81`   | `proxy.lan.zanbaldwin.com`   |
| OpenCloud              | `9200` | `drive.lan.zanbaldwin.com`   |
| Vaultwarden            | `2489` | `vault.lan.zanbaldwin.com`   |
| WebDAV                 | `6065` | `webdav.lan.zanbaldwin.com`  |

# Secrets
> `/mnt/tank4/secrets`

- `postgres/root`
- `postgres/immich`
- `cloudflare` (DNS Zone API Key)
- `tailscale` (machine auth key)
- `webdav/config.yaml` (WebDAV server config: users, bcrypt passwords, per-user directories)

# Mounts

```
nas.lan.zanbaldwin.com:<server-path> <local-path> nfs rw,vers=4.1,proto=tcp,_netdev,nofail,x-systemd.automount,x-systemd.idle=10min,x-systemd.device-timeout=10s 0 0
```
