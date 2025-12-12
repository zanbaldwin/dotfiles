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
 │       ├─ explorer
 │       ├─ navidrome
 │       ├─ proxy
 │       │   ├─ config
 │       │   └─ certs
 │       └─ tailscale
 └─ pool(tank4)
     ├─ class1
     │   ├─ secrets
     │   ├─ books
     │   └─ photos
     └─ class2
         ├─ music
         └─ photos
```

# Port Mappings

| Service                | Port   | Proxy Domain                 |
|------------------------|--------|------------------------------|
| Calibre Content Server | `2254` | `calibre.lan.zanbaldwin.com` |
| Calibre Web            | `8083` | `books.lan.zanbaldwin.com`   |
| Container Updates      | `8321` | `cup.nas.lan.zanbaldwin.com` |
| Next Explorer          | `3453` | `files.lan.zanbaldwin.com`   |
| Navidrome              | `4533` | `music.lan.zanbaldwin.com`   |
| Immich                 | `2283` | `photos.lan.zanbaldwin.com`  |
| Nginx Proxy Manager    | `81`   | `proxy.lan.zanbaldwin.com`   |

# Secrets
> `/mnt/tank4/class1/secrets`

- `postgres/root`
- `postgres/immich`
- `cloudflare` (DNS Zone API Key)
- `tailscale` (machine auth key)
