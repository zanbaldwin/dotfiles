# NAS Self-Hosting: Inventory & Suggestions

## Current Inventory

| Area       | Running                                                              |
|------------|----------------------------------------------------------------------|
| Infra      | Nginx Proxy Manager, Tailscale, Cloudflare Tunnel (public), Backrest |
| Data       | Postgres 18 (VectorChord + PostGIS), Valkey, Garage S3 + UI          |
| Dev        | Forgejo + Actions runner (DinD), code-server, rsync deploy target    |
| Media      | Immich, Navidrome (+ Audible dir), Spindle scrobble stats            |
| Reading    | Calibre-Web, rawr (custom Rust, AO3 archive), Anki sync              |
| Notes/Files| Standard Notes (+ GoAws), Filebrowser Quantum, WebDAV                |
| Location   | Dawarich (+ Sidekiq), Photon geocoder, Timelinize                    |
| Other      | Vaultwarden, Open WebUI (Ollama on desktop), static nginx sites      |

Already tried or considered (not suggested again): OpenCloud, Next Explorer, Memos, Cup,
Karakeep, AppFlowy, Tolaria.

Patterns: quantified-self (location, scrobbles, timeline), digital preservation (AO3,
Audible), Rust preference, existing shared Postgres, loopback-bound ports behind NPM.

## Strongest Fits

1. **Audiobookshelf**: audiobooks and podcasts. You serve Audible files through Navidrome,
   which does not handle chapters, per-book progress or listening sessions. The apps sync
   progress across devices.
2. **Ryot** (Rust): tracks books, films, TV, games, anime and podcasts. Integrates with
   Audiobookshelf, Jellyfin and Kodi. It is like Spindle for everything except music.
3. **Protomaps PMTiles (+ Valhalla)**: completes the location stack. You already
   self-host geocoding (Photon), but map tiles probably still come from a third party. A
   PMTiles extract is one static file that your existing nginx or Garage can serve.
   Valhalla adds routing.
4. **Pocket ID**: a passkey-only OIDC provider. Immich, Forgejo, Open WebUI and Dawarich
   all support OIDC, so you get one login for all of them. It is much lighter than
   Authentik or Keycloak.
5. **Stalwart** (Rust): CalDAV, CardDAV, WebDAV and JMAP/IMAP. Calendar and contacts are
   the most obvious data-sovereignty gap in the current stack. You can use it only for
   *DAV and skip email delivery.
6. **Renovate (in Forgejo Actions)**: opens PRs against this repo when pinned image tags
   go stale. It replaces Cup and the manual version-bump commits.

## By Category

### Quantified Self
- **Wakapi**: WakaTime-compatible server for coding time per project and language.
- **Atuin server** (Rust): shell history sync between machines. Can use the shared Postgres.
- **Open Archiver**: searchable email archive that imports from Gmail, Microsoft 365 or
  IMAP. You keep a copy of your email without running SMTP. Bichon is a Rust alternative.

### Preservation
- **Kiwix**: offline Wikipedia, Wiktionary, Stack Exchange and others as ZIM files.
- **Pinchflat** or **Tube Archivist**: archive YouTube channels and playlists. Pinchflat
  is simpler; Tube Archivist has a full UI.
- **ArchiveBox**: full web page archives (WARC, PDF, screenshots). Also useful for AO3
  works that are not on AO3.

### Reading and Learning
- **Miniflux**: minimal feed reader on Postgres with good keyboard controls.
- **Readeck**: read-later with full-text archive and highlights. Lighter than Wallabag.
- **LinguaCafe** (Laravel) or **Lute v3**: read native text in a target language,
  track known words, export to Anki. Check Korean tokeniser support first.

### Life Admin
- **Paperless-ngx**: OCR and tags for letters from the Belastingdienst, the gemeente,
  insurers and so on. Papra is a lighter alternative.
- **Firefly III** (Laravel) or **Actual Budget**: personal finance. Firefly's data
  importer reads CAMT.053/CSV exports from Dutch banks.

### Communication and Identity
- **Continuwuity** (Rust Matrix homeserver) + mautrix bridges: keep your own copy of
  WhatsApp and Signal history.
- **GoToSocial**: lightweight single-user ActivityPub server, reachable through the
  existing Cloudflare Tunnel.
- **Headscale**: self-hosted Tailscale control plane. A small VPS is better than the NAS
  for this. You lose some Tailscale conveniences.
- **syncstorage-rs** (Rust): self-hosted Firefox Sync storage. Authentication still uses
  Mozilla accounts.

### Ops
- **ntfy**: push notifications from Backrest (via Shoutrrr), Forgejo Actions and scripts.
- **Healthchecks**: dead-man's switch for `cron/dump-postgres.sh` and Backrest plans.
- **Dozzle**: live container log viewer.

### AI Stack
- **SearXNG**: private metasearch. Use it as the Open WebUI web-search backend.
- **Speaches**: OpenAI-compatible speech-to-text and text-to-speech (faster-whisper)
  for Open WebUI voice mode.

### Small Utilities
- **CyberChef** / **IT-Tools**: local JWT, base64 and hash tools, so that client tokens
  do not go into random websites. CyberChef is static and works from the `sites` nginx.
- **Opengist**: Git-backed gists. Forgejo does not have gists.
- **changedetection.io**: watch web pages for changes.
- **Stirling PDF**: PDF tools without uploading to iLovePDF and similar sites.

## Notes
- Forgejo already includes Cargo, OCI and generic package registries. You can use these
  to distribute the custom Rust binaries instead of bind-mounting them.
- Many of the suggestions above can use the existing Postgres: Miniflux, Atuin, Firefly
  III, Wakapi, Pocket ID, Open Archiver.
- Recommendations are from knowledge up to mid-2026. Check project status before you adopt one.
