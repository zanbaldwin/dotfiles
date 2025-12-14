I have two machines:
- my home server, connected to my home LAN, running TrueNAS.
- my laptop (this machine), currently located at my work office (not connected to my home LAN).

Both machines are running Tailscale and connected to my Tailnet (you can confirm via the screenshot located at `tailscale-machines.png`).
- My TrueNAS server is running Tailscale as a manual TrueNAS app, using the YAML found in `compose.server.yaml`
- My laptop (this machine) is running Tailscale using the Docker Compose configuration found in `compose.laptop.yaml`

> On this machine, Tailscale is running and logged-in via the container `network-tailscale-1` and NOT via `tailscale` on the host.
> You can check this by running `docker exec -it network-tailscale-1 tailscale status`, and comparing it to `tailscale status`.

My TrueNAS server is running Immich as a service. When connected to my home LAN, that service can be reached via `photos.lan.zanbaldwin.com` which resolves to `192.168.1.86` (the DNS records are set in Cloudflare so they are available globally, not just on the LAN).

On my Tailnet, I have set my TrueNAS server to be a subnet router for `192.168.1.0/24` (approved in the admin console), and have set the kernel settings described in `truenas-tailscale-settings.conf`.

You are running on my laptop, and you need to diagnose why I can't access Immich through `photos.lan.zanbaldwin.com`.
I have a connection to my server via TeamViewer in order to manually execute commands if you need me to, but I cannot copy and paste output back to you.
