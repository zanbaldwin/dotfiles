# NAS Backup Strategy

Planning document. No changes have been made to the NAS or to `backrest.json`.

## Goals (confirmed)

1. **Hardware redundancy / offsite (3-2-1):** Backblaze B2 is the primary offsite for everything. AWS S3 (Glacier-class) is a secondary offsite for the *critical* tier — provider-redundancy on the data that would actually disrupt life if lost. ZFS on `tank4` + TrueNAS snapshots cover local redundancy/human-error.
2. **Protection against credential theft / ransomware on the NAS:** The B2 and S3 credentials sitting on the NAS must not be able to *delete* what's already backed up.
3. **Protection against human error:** ZFS snapshots are the first line; B2/S3 retention is the second.
4. **Moderate retention** at B2 list pricing; longer retention for critical, shorter for media.
5. **Two tiers, split by life-impact:** *critical* = losing this causes ongoing real-world friction (passwords, app state, source code, secrets). *media* = losing this is painful and irreplaceable in personal terms but you survive without it (photos, music, books, drive).

## Diagnosis: what the current config actually covers

The Backrest config currently has two plans:

| Plan | Source | Backed up? |
|---|---|---|
| `B2-Class1` | legacy path under `/mnt/tank4` — verify in Backrest UI; predates the dataset flattening | Yes |
| `B2-Postgres` | `/mnt/tank4/backups/postgres` | Yes |

> **Note on nomenclature.** Earlier iterations of this strategy used a `class1/class2/class3` directory hierarchy on `tank4` to encode criticality. That structure has been retired — the datasets on `tank4` are now flat (`backups`, `books`, `code`, `drive`, `music`, `photos`, `secrets`). Criticality is expressed in the Backrest plan layout (which bucket + which retention shape), not in the directory layout. The legacy `B2-Class1` plan name predates this and is rotated out as part of the migration below.

Compared to what's on the NAS, the following is **not currently backed up**:

| Path | Size | Tier (new) | Notes |
|---|---|---|---|
| `tank4/photos` | 69 GB | media | Immich originals. |
| `tank4/music` | 103 GB | media | |
| `tank4/code` | 162 MB | critical | Forgejo bare repos. |
| `tank4/drive` | 4.9 GB | media | General file dump. |
| `tank4/backups` | 339 MB | n/a | Stale `postgres.sql` leftover — delete via WebUI. |
| `fast/apps/*` | ~32 MB | critical | NPM config + LE certs, Navidrome DB, Memos files (DB in Postgres), Calibre-Web, Tailscale state. |
| Forgejo support dirs (`ssh/`, `app.ini`, `git/lfs/`) | 375 K | skipped | Per your decision. See "Forgejo/Immich support-dir risk note" below. |
| Immich support dirs (thumbs, encoded-video, upload staging, profile) | 24 G | skipped | Regenerable (thumbs 7.5G, encoded-video 16G, upload staging 646M). |

Together this is ~178 GB of currently-unprotected data. At B2 list price (~$0.006/GiB-month) that's about **$1.07/month** of B2 storage, plus a small overhead for retention.

## Recommended structure

**Two buckets, split by life-impact**: *critical* (things that disrupt life if lost) vs *media* (things that hurt to lose but you survive). **One Restic repo per bucket** with Backrest plans tagging snapshots by source. **Two-key Restic pattern** on each bucket. **Both tiers mirrored to AWS S3 Glacier Instant Retrieval** as a second offsite. **Skip the Forgejo/Immich support directories** (regenerable thumbs/encoded-video, in-flight uploads, SSH host keys, etc. — see risk note below).

### Buckets

```
zanbaldwin-nas-critical    ← ~1.3 GiB, life-impact data. Mirrored to B2 + S3 Glacier IR.
zanbaldwin-nas-media       ← ~189 GiB, irreplaceable. Mirrored to B2 + S3 Glacier IR.
```

The S3 mirror covers both tiers. At GLACIER_IR pricing (~$0.004/GiB-month) the media mirror costs ~$0.76/month for 189 GiB — cheap enough that "media is replaceable from other sources" no longer outweighs true provider-redundancy. Photos in particular have unique sentimental value that no streaming service or re-acquisition path restores. With both tiers on both providers, the catastrophic loss scenario requires *simultaneous* failure of B2 and AWS, which is genuinely improbable.

### Restic repos

**One repo per bucket, one Backrest plan per repo.** Each plan carries all the source paths for its tier as a single include list, fires once per schedule, and produces one snapshot per run covering everything in that tier. Backrest automatically tags each snapshot with `plan:<plan-id>` and `created-by:<instance-id>` — you don't configure this. Because each repo holds only one plan's snapshots, retention applies cleanly to the whole repo at prune time with no `--tag` filtering needed.

| Bucket | Repo URI | Plan | Approx. size |
|---|---|---|---:|
| `zanbaldwin-nas-critical` | `s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-critical/` | `critical` | ~1.3 GiB |
| `zanbaldwin-nas-media` | `s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-media/` | `media` | ~189 GiB |
| `zanbaldwin-nas-critical-s3` *(mirror)* | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/` | `critical-s3` | ~1.3 GiB |
| `zanbaldwin-nas-media-s3` *(mirror)* | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-media-s3/` | `media-s3` | ~189 GiB |

> Restic talks to B2 via the **S3-compatible endpoint**, not via the native `b2:` URI scheme. The native backend in restic is currently unusable against newer/Enterprise-provisioned B2 accounts — `b2_authorize_account` fails with `400: This request is not currently supported on API version number 3` (restic issue [#5741](https://github.com/restic/restic/issues/5741), open since 2026-03). Backblaze's own [restic integration guide](https://www.backblaze.com/docs/cloud-storage-integrate-restic-with-backblaze-b2) documents S3-compatible as the only supported configuration. The buckets themselves are still created/managed in B2 (Object Lock, lifecycle rules, caps — all unchanged); only the wire protocol restic uses differs.

Trade-off vs the previous "8 repos, 8 plans" idea: collapsing to one plan per repo means everything in a tier shares a single snapshot lineage and a single retention shape. The cost is that you can no longer differentiate retention or schedule between sources within a tier — but in this strategy all four critical sources already shared the same retention shape, and the media split (photos/music monthly=3 vs books/drive monthly=6) differs by only a few percent of storage, easily unified. The blast radius from repository corruption goes up — losing one repo loses one bucket's worth — but B2 versioning + the 30-day lifecycle rule mitigates that, and the S3 mirror on both tiers protects against catastrophic loss of the bucket itself.

### What goes in each plan

**`critical` plan (repo `zanbaldwin-nas-critical`):** all four critical sources in one include list.

| Source | Why critical |
|---|---|
| `/mnt/tank4/secrets` | Postgres root password, B2 keys, Cloudflare API key, Tailscale auth key, scheduled Bitwarden encrypted-JSON exports (see paper-recovery section). |
| `/mnt/tank4/backups/postgres` | All app DB dumps — Forgejo (issues/PRs/users), Immich (tags/albums), Memos. Losing this is losing every app's functional state. |
| `/mnt/tank4/code` | Forgejo bare repos. If Forgejo is the only home for any repo (no GitHub/Codeberg mirror), this *is* the source of truth. |
| `/mnt/fast/apps` (excludes below) | NPM proxy DB + Let's Encrypt cert state (avoids LE rate-limit pain on rebuild), Tailscale node key, Calibre/Navidrome/Memos config and per-app file state. |

**`media` plan (repo `zanbaldwin-nas-media`):** all four media sources in one include list.

| Source | Why media |
|---|---|
| `/mnt/tank4/books` | Calibre library — books are findable from origin. The Calibre metadata layer (tags, shelves) lives in `apps`. |
| `/mnt/tank4/photos` | Immich library. Irreplaceable personally; survivable functionally. Devices typically also retain originals. |
| `/mnt/tank4/music` | Replaceable in principle (streaming/re-rip), prohibitive effort cost. |
| `/mnt/tank4/drive` | General file dump. |

The `critical-s3` and `media-s3` mirror plans on the S3 side hold the same include lists, pointed at their respective S3 repos.

### Retention shapes (one per plan)

The `critical` plan gets long retention — you want the ability to roll back six months when you discover something was quietly corrupted:

```
critical, critical-s3:
  daily=14   weekly=8   monthly=12   yearly=2
```

The `media` plan gets shorter retention — large data with low churn means deep history is mostly redundant with the previous snapshot. Media was originally split between `photos`/`music` (monthly=3) and `books`/`drive` (monthly=6); the difference is a few percent of storage on stable data — unified to monthly=6 for simplicity:

```
media, media-s3:
  daily=7    weekly=4   monthly=6    yearly=1
```

The monthly prune ceremony (later section) applies each shape once per repo, with no `--tag` filtering needed.

### Two-key pattern on both providers, S3 mirror running independently

Each of the four repos (B2 critical, B2 media, S3 critical, S3 media) has its own write-only backup credential in Backrest, and its own admin credential in Bitwarden cloud (mirrored on the paper recovery sheet — see the "Root of trust" section). The S3 mirrors run as *independent* second plans against the same sources — not as a downstream `restic copy` from B2. The reason: independent plans survive single-provider outages. If B2 is unreachable when the schedule fires, S3 still gets a fresh snapshot, and vice versa.

Cost of independence: source files are read twice during the backup window (once per provider). Even for media's ~189 GiB, two sequential reads from ZFS during the overnight window is well within budget.

## Two-key Restic pattern on B2 — *plus* bucket-level version protection

The single-key setup today (`B2_ACCOUNT_ID` / `B2_ACCOUNT_KEY` with full bucket permission) is the credential-theft risk you flagged. The two-key split below handles *deletion*, but not *version-stomping*, so it must be paired with bucket-level version retention (next subsection).

### Backup key — lives on the NAS (in Backrest)

One B2 *application key* per bucket. Capabilities:

```
listBuckets, listFiles, readFiles, writeFiles
```

Crucially **no `deleteFiles`** and **no `deleteKeys`**. With this key, the NAS can `restic backup` and `restic check` but cannot `restic forget`, cannot `restic prune`, and cannot delete the repo. A compromised NAS cannot delete what's been backed up.

(Note: `readFiles` is needed because Restic verifies what it just wrote and may re-read pack/index files during a backup. Without it, backups can fail.)

### Why `writeFiles` alone is not "append-only" — the version-stomping gap

B2 files are versioned: uploading a file with the same name as an existing one creates a *new version*; the old version persists until something with `deleteFiles` removes it. With only `writeFiles`, an attacker on the NAS:

- **Cannot** delete existing versions.
- **Can** upload zero-byte or junk versions with the same names as Restic's pack/index/snapshot files. By default B2 returns the latest version on name-based reads, so a normal `restic snapshots` from a fresh client sees the junk and reports the repo broken. The good versions still exist in B2 but are no longer "latest".
- **Can** cause cost amplification by uploading large garbage files — the capability model does not bound this.

This means the two-key split alone does not give "credentials on the NAS can't damage what's been backed up". It must be paired with one of the two protections below, plus a billing cap.

### Required bucket-level protections (pick at least one of A or B; do C in both cases)

**A — Lifecycle rule: keep prior versions for ≥30 days**  *(minimum recommendation)*
On each bucket, set the B2 lifecycle policy to retain non-current versions for at least 30 days after they're superseded. A version-stomping attack now becomes recoverable: junk becomes "latest", original stays in version history, admin key cleans up the junk, original is restored as latest. No additional storage cost unless an attack actually happens (you only pay for the overlapping versions during their retention).

**B — Object Lock with governance-mode default retention** *(strong guarantee, slight ops cost)*
Enable Object Lock on each bucket with a 14-day default retention in governance mode. Every uploaded version is locked from deletion (even by the admin key) for 14 days. Object Lock does **not** prevent a `writeFiles`-only attacker from creating new versions, but it makes the old versions provably undeletable for the lock window — guaranteeing the recovery path works even if the admin key itself is compromised within the same incident. Pruning data younger than the lock period requires `bypassGovernance` on the admin key (governance mode, unlike compliance mode, allows override). For your retention shapes the lock window is far shorter than the smallest "daily" bucket, so prune is not impacted in practice.

**C — Storage / spend caps on both buckets** *(do this regardless of A or B)*
Set a Bucket Cap (B2 dashboard → bucket → caps) on storage size or daily bytes-uploaded. Without a cap, a write-only NAS key can still rack up arbitrary cost via garbage uploads. A cap that's 2–3× current usage with an email alert is sensible.

### Admin key — kept in Bitwarden cloud + on the paper recovery sheet, *not* stored on the NAS

One B2 application key (or a single all-bucket key) with full access including `deleteFiles`. Used for:

- `restic forget --prune` to actually reclaim space
- `restic rebuild-index` if a repo ever goes inconsistent
- `restic check --read-data` if you want full integrity scrubs
- Repository password rotation
- Emergency restore from a fresh machine

This key never touches the NAS filesystem and never goes into the Backrest config.

### Operational consequence: where does `prune` happen?

This is the only awkward bit of the two-key pattern. Restic *prune* is the operation that frees space, and it requires `deleteFiles`. With the backup key on the NAS, Backrest's automatic prune (`prunePolicy` in `backrest.json`) **will fail** — the key can't delete.

Two clean options:

1. **(Recommended)** Run prune from your laptop/desktop, monthly, manually. Concretely:
   ```
   export AWS_ACCESS_KEY_ID=...      # admin key keyID
   export AWS_SECRET_ACCESS_KEY=...  # admin key applicationKey
   export AWS_DEFAULT_REGION=eu-central-003
   restic -r s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-critical/ forget --prune \
       --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2
   # repeat per repo (four total: B2 critical, B2 media, S3 critical, S3 media)
   ```
   Trade: requires monthly discipline. Win: NAS compromise is structurally incapable of damaging the offsite.

2. **Hybrid** — Run a *second* Backrest instance on your desktop pointed at the same repos with the admin key, with the prune schedule enabled there and the backup schedule disabled. Same end result, less manual ceremony. Cost: another small piece of infrastructure to maintain.

Either way: **remove `prunePolicy` from the NAS Backrest config** — or set it to never run. Leaving it scheduled there with a write-only key just means error emails forever.

`checkPolicy` on the NAS-side is fine to keep (it only reads).

## Postgres backup — host cron, not Backrest hook

### Why host cron and not a Backrest pre-backup hook

Backrest runs as a Docker container. To run `pg_dump` against the postgres container, it would need to either (a) `docker exec` from inside Backrest — requires mounting the Docker socket into Backrest, which is root-equivalent on the host and silently undoes the entire containerization-isolation story; or (b) call a webhook on the host that runs pg_dump — extra moving part, another service to harden.

The clean answer: **host cron does the dump; Backrest backs up the resulting file.** The implementation lives at `cron/dump-postgres.sh` in this repo. Key design points:

1. **Per-database dumps in plain SQL, deterministically formatted.** The script uses `pg_dump --inserts --column-inserts --clean --if-exists --quote-all-identifiers --disable-dollar-quoting` plus `pg_dumpall --globals-only` for roles/tablespaces. This is *deliberately* plain SQL rather than custom format (`-Fc`):

   - **De-dup friendliness.** Plain SQL with `--inserts --column-inserts` produces one INSERT statement per row, with fully-qualified column lists and quoted identifiers. Day-to-day diffs are line-level and localised: only the rows that actually changed produce new lines, and Restic's content-defined chunking matches the unchanged regions across snapshots. The same `postgres` tag therefore costs almost nothing per daily snapshot after the first one. `--disable-dollar-quoting` keeps function bodies as standard quoted strings, which also chunk stably.
   - **Custom format (`-Fc`) would defeat this.** It's a compressed binary container; its byte layout changes whenever any row, OID, or internal ordering shifts. Each daily dump would re-chunk almost entirely, dragging the postgres tag's storage cost roughly linearly with snapshot count.
   - **Atomic rotate.** The script dumps into a `mktemp -d` and only `mv`s into `/mnt/tank4/backups/postgres/` once every database succeeds, so Backrest never reads a half-written file mid-rotation.
   - **Trade you're accepting.** Plain SQL restores via `psql -f <file>`, not `pg_restore`. There's no per-table selective restore, no parallel restore. Acceptable for the homelab scale; document it in the restore runbook.

   Host crontab (TrueNAS host or the box running the postgres container):
   ```cron
   MAILTO=root
   0 2 * * * root /usr/local/bin/dump-postgres.sh || \
     curl -fsS -d "pg_dump failed on $(hostname)" https://ntfy.sh/your-private-topic
   ```

   Schedule: dump at 02:00, the Backrest `critical` plan at 03:00 so it picks up the freshly-rotated files via its `/mnt/tank4/backups/postgres` source.

2. **Dump location stays at `/mnt/tank4/backups/postgres/`.** That's where `dump-postgres.sh` already writes; the `critical` Backrest plan includes this path in its source list (reflected in the Step 6 table). No relocation needed.

3. **The stale `/mnt/tank4/backups/postgres.sql`** (339 MB) should be deleted via the TrueNAS WebUI.

### Same pattern for SQLite databases

For Navidrome's SQLite (`fast/apps/navidrome/navidrome.db`), use the same host-cron approach with SQLite's atomic `.backup` command:

```bash
# Add to pg-dump-job.sh or run as a separate host cron
sqlite3 /mnt/fast/apps/navidrome/navidrome.db \
  ".backup '/mnt/fast/apps/navidrome/navidrome.db.backup'"
```

Then add `navidrome.db` (the live one — Backrest could capture mid-write) and `navidrome.db-wal`, `navidrome.db-shm` to the `critical` plan's exclude list. The `.backup` file (consistent snapshot) gets included.

Note: Vaultwarden has been decommissioned in favour of Bitwarden cloud as the primary password manager — see the "Root of trust" section for the rationale (circular dependency: Vaultwarden held the Restic keys needed to recover the NAS that hosted Vaultwarden). Any remaining `tank4/secrets/vault/` and `fast/apps/vaultwarden/` directories are obsolete and can be deleted once you've confirmed migration to Bitwarden cloud is complete.

## Bitwarden vault export — laptop cron, not NAS cron

Bitwarden cloud is the primary, but it has its own failure modes (account suspension, master-password loss, Bitwarden Inc going away). The defence is scheduled encrypted-JSON exports that live in your normal backup pipeline.

### Why laptop and not NAS

Exporting a Bitwarden vault requires the master password — `bw unlock` has no admin-token shortcut by design (the master password derives the encryption key client-side; the server never sees it). Putting the master password into a NAS cron would mean a NAS compromise = vault compromise, undoing the entire reason Bitwarden cloud is primary.

The master password already exists on your laptop (in the OS keychain / `secret-tool` / similar — wherever Bitwarden clients normally cache it). Running the export there piggy-backs on credentials your laptop already legitimately holds, with no additional persistence at rest.

### The flow

A small script in your dotfiles, triggered by a calendar reminder or systemd timer when you're logged in (not a headless daemon):

```bash
#!/bin/bash
set -euo pipefail

EXPORT_PASS="$(secret-tool lookup app bitwarden-export passphrase)"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$HOME/.cache/bw-exports/bw-export-${TIMESTAMP}.json.enc"

mkdir -p "$(dirname "$OUT")"

bw unlock --check >/dev/null || bw login --check >/dev/null || {
  echo "Run 'bw login && bw unlock' interactively first." >&2
  exit 1
}

bw export --format encrypted_json --password "$EXPORT_PASS" --output "$OUT"

# Atomic move to NAS (over Tailscale, scp or rsync)
scp "$OUT" nas:/mnt/tank4/secrets/bitwarden-exports/

# Keep only the last 6 local copies
ls -t "$HOME/.cache/bw-exports/"bw-export-*.json.enc | tail -n +7 | xargs -r rm
```

Key properties:

- **Master password never touches the script.** `bw` reads it interactively from its own cached session; you `bw login && bw unlock` once per session as part of normal Bitwarden use.
- **Export passphrase is separate** from the master password. Stored in the laptop's keychain and on the paper recovery sheet. Compromise of the laptop reveals the export passphrase but not the master password.
- **The output file is `encrypted_json` format** — a Bitwarden-native encrypted export decryptable with the passphrase. Restic encrypts it again on top when it goes into the `critical` plan.
- **The file lands in `/mnt/tank4/secrets/bitwarden-exports/`** which is already in the `critical` plan's source list, so it flows into B2 + S3 GLACIER_IR via the existing nightly backup.

### Schedule

Calendar reminder, monthly (first Sunday). Not a cron — running unattended would require the master password at rest. The reminder fires a ntfy push that points you at the one-line `~/bin/bw-export` invocation. Takes 10 seconds when prompted.

### Cleanup of old exports on the NAS side

The `tank4/secrets/bitwarden-exports/` directory accumulates one file per export. Prune locally on the NAS via a host-cron `find ... -mtime +180 -delete` (keep 6 months of exports on the NAS; Restic snapshots on B2/S3 keep deeper history per their own retention shape). Restoring an old export from B2 is a `restic restore` operation, no different from any other path.

### What this protects against

| Failure | Recovery path |
|---|---|
| Lost laptop, NAS fine | Log into Bitwarden cloud from any device → done. Exports not needed. |
| NAS dead, Bitwarden fine | Log into Bitwarden cloud → get Restic passwords → restore NAS from B2/S3. |
| Bitwarden account locked out, NAS fine | Restore latest export from `/mnt/tank4/secrets/bitwarden-exports/`, decrypt with the export passphrase (paper sheet), import into a fresh Bitwarden account or any other vault. |
| Both dead | Pull export from B2/S3 using Restic credentials from the paper recovery sheet, decrypt with the export passphrase (also paper sheet). The paper sheet is the bootstrap. |

## Excludes for the `critical` plan (and its `critical-s3` mirror)

Most of `fast/apps/*` is small config — back it up. But these `fast/apps` subpaths should be excluded:

- `/mnt/fast/apps/postgres/**` — live DB data dir. The authoritative copy is the pg_dump. Backing up the live data dir = inconsistent snapshots and wasted space.
- `/mnt/fast/apps/paperless/index/**` — regenerable search index.
- `/mnt/fast/apps/paperless/log/**` — logs.
- `/mnt/fast/apps/backrest/cache/**` — Restic local cache, regenerable.

Plus generic excludes from the legacy `B2-Class1` plan (`**/cache`, `**/.cache`, `**/Cache`, `**/*.tmp`, `**/thumbs`, `**/node_modules`, `**/.DS_Store`, `**/.Spotlight-V100`, `**/.Trashes`) — these are sensible on both the `critical` and `media` plans alike.

## Forgejo/Immich support-dir risk note (informational, not a recommendation against your decision)

You chose to skip the Forgejo and Immich *support directories* that live alongside (or under) the main data datasets — they hold either regenerable derivatives (thumbs, encoded video) or small bits of host-side state. Concretely that means after a total-disaster restore:

- **Forgejo SSH host keys** under the Forgejo data dir (`ssh/`) are lost → every existing clone gets `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` until the user re-pins. Annoying, recoverable.
- **Forgejo `app.ini` secrets** (session keys, OAuth client secrets, JWT signing) are lost → everyone re-logs-in once. OAuth integrations to external services need their client secrets re-issued.
- **Forgejo wiki / attachments / LFS** (under `git/lfs/`) are lost. Repo commits survive (those are on `tank4/code`), but anything stored as an attachment or LFS pointer does not.
- **Immich avatars** (`profile/`) lost.
- **Immich in-flight uploads** (`upload/`) — anything not yet template-moved to `tank4/photos`. Usually a handful of files per recent sync.
- **Immich thumbs / encoded-video** — regenerate automatically over hours/days of CPU+GPU time.

If any of those bullets sting more than expected, the surgical fix is to add the Forgejo support dir (~375 KB) to the `critical` plan's source list and continue skipping the Immich-derived dirs. It's a 375 KB add at trivial cost.

## Cost projection

### Empirical baseline

You're currently billed **$0.06 USD over ~5 months** for 12.6 GiB in `zanbaldwin-nas-backup`. That works out to **~$0.012/month** for the existing `secrets/books/postgres` backup. The reason it's so cheap is the account-wide **10 GB free tier**: only ~2.6 GiB is actually billable, giving an effective rate of ~$0.004/GiB-month on the current setup (where the free tier covers 79% of stored data).

The free tier doesn't scale — once total stored data clears 10 GB, you pay list price (**$0.006/GiB-month**, ~$6/TB) for everything above it. Transactions (uploads, downloads, list calls) are billed separately at trivial rates for a backup workload (under $0.01/month at this scale).

### Projected cost of the full strategy

Per-tier breakdown using B2 list price ($0.006/GiB-month) past the 10 GB free tier, and AWS S3 Glacier Instant Retrieval ($0.004/GiB-month) for the S3 mirrors:

| Provider | Bucket | Tier | Approx size | $/month |
|---|---|---|---:|---:|
| B2 | `zanbaldwin-nas-critical` | critical | 1.3 GiB | $0.008 |
| B2 | `zanbaldwin-nas-media` | media | 189 GiB | $1.07 |
| AWS S3 (GLACIER_IR) | `zanbaldwin-nas-critical-s3` | critical mirror | 1.3 GiB | $0.005 |
| AWS S3 (GLACIER_IR) | `zanbaldwin-nas-media-s3` | media mirror | 189 GiB | $0.76 |
| - Free tier (B2 only, 10 GiB) | | | -10 GiB | -$0.06 |
| **Base total** | | | **~382 GiB** | **~$1.78/month** |

Plus retention overhead (typically +15–25% on Restic repos with active churn, much less on the immutable repos): realistic ongoing total **$2.05–$2.25/month**, dominated entirely by media (`music` + `photos`) on both providers.

GLACIER_IR was chosen over Standard-IA for the S3 mirrors: at ~$0.004/GiB-month vs $0.0125/GiB-month it's 3.1× cheaper, restic supports it natively at upload (one env var, no lifecycle rules needed), and restore is still instant (milliseconds, not the multi-hour thaw that Glacier Flexible / Deep Archive require). The 90-day minimum-duration penalty doesn't bite because Restic's content-defined chunking means very little data is actually deleted at prune time, and the data that *is* deleted (mostly small postgres diff chunks) costs single-digit cents per year in phantom storage. The 128 KB minimum object size adds a few MB of "rounded up" billable size across metadata — pennies. The headline 3.1× saving is real for this workload.

Note: if you enable Object Lock with a 14-day default retention, pruned data keeps being billed until its lock expires. For your retention shapes that adds maybe 1–2 GiB of "ghost storage" at any given time — about $0.01/month. Not material.

### Cost over the first year

Initial seed uploads are free on both B2 and AWS S3. Once seeded, expect:

- Month 1–2: ~$2.10/month as indices settle
- Steady state: ~$2.20/month, drifting up by maybe $0.10/month per year as photos/music grow (growth lands on both B2 and S3)
- Version-stomping incident (if it happens): temporary doubling for the 30-day version retention window. Worst case caps at ~$4.40/month for one month.

The version-retention lifecycle rule is essentially free in normal operation — old versions only accumulate during the brief moment between an old pack being superseded and the lifecycle rule expiring it.

## B2 admin panel setup — step by step

This is the order to do things in the Backblaze B2 web console. You do **not** need the B2 CLI installed for the bucket setup, but you **do** need it (or `curl` against the B2 API) for the granular application keys, because the web UI only offers "Read/Write" or "Read-Only" presets — not the write-without-delete combination we need.

### Prerequisites

Install the B2 CLI somewhere you control (your laptop, not the NAS):

```bash
# Recommended: pipx
pipx install b2

# Or: pip
pip install --user b2

# Verify
b2 version
```

Authorize the CLI with your master account credentials *once* (so you can mint application keys). After the keys are minted, you'll reauthorize the CLI with the *admin key* (not the master) for day-to-day use.

```bash
b2 account authorize     # uses application keyID + applicationKey
```

### Step 1 — Create the two buckets

In the B2 console: **Buckets → Create a Bucket** (or *My Buckets* page → *Create a Bucket*). Repeat for each.

**Bucket 1: `zanbaldwin-nas-critical`** (or reuse the existing `zanbaldwin-nas-backup` — see migration note below).

| Setting | Value |
|---|---|
| Bucket Unique Name | `zanbaldwin-nas-critical` (B2 names are globally unique; if taken, prefix with random) |
| Files in Bucket | Private |
| Object Lock | **Enable** (only if going with Option B). Default mode: **Governance**. Default retention period: **14 days**. *Note: Object Lock can only be enabled at bucket creation. If reusing the existing bucket, you cannot retroactively enable it without bucket recreation.* |
| Default Encryption | **Enable** with SSE-B2. Free, server-side, transparent. Restic already encrypts at the application level, so this is defense-in-depth against B2-side mishaps. |
| File Lock | Don't confuse with Object Lock — leave file-level lock off; rely on bucket-default retention. |

**Bucket 2: `zanbaldwin-nas-media`** — same settings.

#### Migration note

You have an existing `zanbaldwin-nas-backup` with two Restic repos (`/class1`, `/database/postgres`) and 12.6 GiB of data. Since the new layout uses a *different repo structure* (one repo per bucket, one fat plan per repo, not multiple repos at sub-paths), there's no clean way to "repurpose" the existing bucket without ending up with mixed-layout cruft. **Recommended path: clean slate.**

- **Clean slate (recommended).** Create both new buckets fresh (`zanbaldwin-nas-critical`, `zanbaldwin-nas-media`). `restic init` one new repo per bucket. Run fresh backups — uploads to B2 are free, so re-seeding the existing 12.6 GiB of data costs nothing. Once new backups verify, delete the old `zanbaldwin-nas-backup` bucket and the old Restic repos in it. You lose the existing snapshot history (a few months of class1 + postgres) but gain a clean structure aligned to the new strategy.

For inheriting Object Lock: it can only be enabled at bucket creation, so the clean-slate path also gets you Object Lock if you decide to enable it (Option B in the protections section).

### Step 2 — Configure Lifecycle Rules (per bucket)

In the B2 console: **Buckets → [bucket name] → Lifecycle Settings**.

Click **Use a custom lifecycle rule** and set:

| Field | Value | Meaning |
|---|---|---|
| File Name Prefix | (empty — applies to all files in bucket) | |
| Days from uploading to hiding | (empty / "Never") | Don't auto-hide current versions. |
| Days from hiding to deleting | **30** | Once a version is superseded (hidden because a newer version was uploaded), keep it 30 days, then delete. |

What this does: if a `writeFiles`-only attacker uploads zero-byte versions over your packs, the original versions become "hidden" automatically (by virtue of a newer version existing) and are retained for 30 days. The admin key can restore them within that window. After 30 days of normal operation with no attack, old superseded versions are auto-cleaned and don't bloat storage.

Save the rule. Repeat for both buckets.

### Step 3 — Configure Caps & Alerts (account-wide)

In the B2 console: **Account → Caps & Alerts** (also reachable from the top-right account menu).

Set:

| Cap | Value | Why |
|---|---|---|
| Daily Storage Cap | **$5/day** | At normal usage you'll never approach this. An attacker on the NAS spamming uploads would, alerting you fast. |
| Daily Download Bandwidth Cap | **$2/day** | You almost never download from B2 (restores are rare). A cap catches an exfiltration attempt. |
| Daily Class C Transactions Cap | **$1/day** | Class C = listing/metadata calls. Same reasoning. |

For alerts, set email notifications when usage exceeds 50% and 80% of caps. If you have multiple email addresses (admin / personal), add both.

B2's caps are account-wide, not per-bucket, but at your storage scale you'll get the desired effect anyway. Once you're at the cap, B2 returns API errors instead of letting more transactions through.

### Step 4 — Create the two application keys

This is the part where the web UI is insufficient. Use the B2 CLI from your laptop.

**4a) Backup key (lives on the NAS, in Backrest)**

For each bucket, create a key with exactly these capabilities. Critically **omit `deleteFiles`, `deleteBuckets`, `writeBucketRetentions`, `writeBucketEncryption`, `bypassGovernance`**:

```bash
b2 key create \
  --bucket zanbaldwin-nas-critical \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,readBucketEncryption \
  backrest-nas-critical
```

```bash
b2 key create \
  --bucket zanbaldwin-nas-media \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,readBucketEncryption \
  backrest-nas-media
```

Each command prints a `keyID` and `applicationKey` **once**. Capture both. Because restic talks to B2 via the S3-compatible endpoint (see note in the "Restic repos" section), the `keyID` becomes `AWS_ACCESS_KEY_ID` and the `applicationKey` becomes `AWS_SECRET_ACCESS_KEY` in the Backrest UI's repo configuration (one set per repo, scoped to its bucket).

**4b) Admin key (lives in Bitwarden cloud + paper recovery sheet, *not* on the NAS)**

One key with full access to both buckets. If you went with Option B (Object Lock), also include `bypassGovernance` so prune can override the lock on legitimately-expired retentions:

```bash
b2 key create \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,deleteFiles,readBuckets,writeBuckets,readBucketEncryption,writeBucketEncryption,readBucketReplications,writeBucketReplications,readBucketRetentions,writeBucketRetentions,readFileRetentions,writeFileRetentions,readFileLegalHolds,writeFileLegalHolds,bypassGovernance,listAllBucketNames \
  admin-prune-restore
```

(Drop `bypassGovernance` and the file-retention caps if you didn't enable Object Lock.)

Capture the output. Store both `keyID` and `applicationKey` as a Bitwarden cloud secure note and copy onto the paper recovery sheet — never in any config file on the NAS.

**4c) Verify capability scope**

From your laptop, with the admin key authorized:

```bash
b2 account authorize <admin keyID> <admin applicationKey>
b2 key list
```

You should see three keys: master (the account-level one), the two backup keys, and the admin key. Confirm each backup key's `capabilities` field shows the intended list and that `deleteFiles` is not present.

### Step 5 — Test the credential isolation before going live

Before pointing Backrest at the new keys, prove they behave as expected. From your laptop:

```bash
# Authorize as the (write-only) backup key
b2 account authorize <backup-nas-critical keyID> <backup-nas-critical applicationKey>

# This should succeed
echo "test content" | b2 file upload zanbaldwin-nas-critical - test/capability-probe.txt

# This should FAIL with an authorization error — proof deleteFiles is denied
b2 file delete b2id://<fileId from previous upload>
```

If both behave as described, the key is correctly scoped. Run the same probe against `zanbaldwin-nas-media`. Then *also* upload a second version of the same file name and confirm via the admin key that both versions exist — this verifies versioning is on and the lifecycle rule is in scope:

```bash
b2 account authorize <admin keyID> <admin applicationKey>
b2 file-version list zanbaldwin-nas-critical test/capability-probe.txt
# Should show two versions
```

Clean up:

```bash
b2 file delete zanbaldwin-nas-critical test/capability-probe.txt
b2 file-version list zanbaldwin-nas-critical test/capability-probe.txt
# Now delete each remaining version by fileId
```

Then verify the *same key* authenticates against the S3-compatible endpoint (which is what restic will actually use):

```bash
AWS_ACCESS_KEY_ID=<backup-nas-critical keyID> \
AWS_SECRET_ACCESS_KEY=<backup-nas-critical applicationKey> \
  aws s3 ls s3://zanbaldwin-nas-critical/ \
    --endpoint-url https://s3.eu-central-003.backblazeb2.com
# Should return an empty listing (or whatever is in the bucket) with no auth error
```

If this succeeds, Backrest's `restic init` against the same endpoint will also succeed.

### Step 6 — Update Backrest

In the Backrest web UI (`backup.lan.zanbaldwin.com`):

**Add the two B2 repos** (S3 repo added in a separate section below):

| Repo | URI | Env vars |
|---|---|---|
| `b2-critical` | `s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-critical/` | `AWS_ACCESS_KEY_ID` (= keyID) + `AWS_SECRET_ACCESS_KEY` (= applicationKey) from the `backrest-nas-critical` key, plus `AWS_DEFAULT_REGION=eu-central-003` |
| `b2-media` | `s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-media/` | `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` from the `backrest-nas-media` key, plus `AWS_DEFAULT_REGION=eu-central-003` |

For each new repo:
- Set a strong Restic password (different for each repo). **Store both passwords in Bitwarden cloud and copy onto the paper recovery sheet** before doing anything else — these are the keys that decrypt every backup, losing them turns the offsite into a sealed brick.
- **Remove or disable** the `prunePolicy` on the repo — you'll prune from your laptop with the admin key. The backup key cannot delete, so leaving prune enabled produces error notifications forever.
- `checkPolicy` can stay — it only reads.
- Let Backrest run `restic init` on first save.

**Add plans:**

One plan per repo. Each plan automatically tags its snapshots with the plan ID.

| Plan ID | Repo | Sources | Retention shape | Schedule |
|---|---|---|---|---|
| `critical` | `b2-critical` | `/mnt/tank4/secrets`, `/mnt/tank4/backups/postgres`, `/mnt/tank4/code`, `/mnt/fast/apps` (excludes below) | 14d/8w/12m/2y | `0 3 * * *` (after pg_dump cron at 02:00) |
| `media` | `b2-media` | `/mnt/tank4/books`, `/mnt/tank4/photos`, `/mnt/tank4/music`, `/mnt/tank4/drive` | 7d/4w/6m/1y | `30 2 * * *` |

The `critical` plan fires at 03:00 so its `postgres` source picks up the freshly-rotated pg_dump output. The `media` plan has no such dependency and runs at 02:30 in parallel against a different repo.

Once the new backups verify successfully (a snapshot landed in each repo), delete the old `B2-Class1` and `B2-Postgres` plans/repos and the old `zanbaldwin-nas-backup` bucket.

### Step 7 — Rotate / revoke the old master-keyed access

Once everything is migrated and verified:

In the B2 console: **App Keys → [old master/full key used in current `backrest.json`] → Delete**.

This removes the old single-credential blast-radius from the system. The master account key (the one tied to your login) stays — you'll need it occasionally to mint new keys — but it should never live in any config file.

### Step 8 — Monthly prune ceremony (from your laptop)

Add a calendar reminder for the first Sunday of each month. Two repos to prune on B2; S3 critical mirror is pruned in the S3 section below.

```bash
# Authorize with the admin B2 key, via the S3-compatible endpoint
export AWS_ACCESS_KEY_ID=<admin keyID>
export AWS_SECRET_ACCESS_KEY=<admin applicationKey>
export AWS_DEFAULT_REGION=eu-central-003

# Critical repo — single plan, single retention shape
restic -r s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-critical/ forget --prune \
  --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2

# Media repo — single plan, single retention shape
restic -r s3:s3.eu-central-003.backblazeb2.com/zanbaldwin-nas-media/ forget --prune \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
```

Two commands total, one per repo. With the fat-plan layout (one Backrest plan per repo, each carrying all the source paths for that tier), every snapshot in a repo shares the same `plan:` tag and the same retention shape, so `--tag` filters and `--group-by tag` are no longer needed.

(The B2 admin key's native `deleteFiles` capability maps to `s3:DeleteObject` at the S3-compatible endpoint — the same key works for prune against either API.)

Restic's repo passwords (separate from the B2 keys) live in `backrest.json` on the NAS — they're also stored in Bitwarden cloud and on the paper recovery sheet per "Adjacent concerns #1". The Restic password is what actually encrypts the backup data; the B2 key is only access control on the storage side.

## AWS S3 mirror for both buckets — step by step

Both tiers get a second offsite on AWS S3 Glacier Instant Retrieval, giving you full provider-redundancy: if Backblaze is unreachable (account suspension, regional outage, billing dispute), AWS still has a complete snapshot history of everything. The scenario this defends against is **simultaneous** failure of NAS + B2 — single-provider redundancy on B2 isn't enough when that very provider is the failure mode.

### Storage class: GLACIER_IR

Storage classes considered for `eu-west-1` (Ireland):

| Class | $/GiB-mo | 190 GiB/mo | Min duration | Min obj size | Retrieval time | Restic compat |
|---|---:|---:|---|---|---|---|
| Standard | $0.023 | $4.37 | none | none | instant | Native |
| Standard-IA | $0.0125 | $2.38 | 30 d | 128 KB | instant | Native |
| **Glacier Instant Retrieval** *(chosen)* | $0.004 | $0.76 | 90 d | 128 KB | instant (ms) | Native |
| Glacier Flexible Retrieval | $0.0036 | $0.68 | 90 d | 40 KB | 1 min–12 h | Needs lifecycle split |
| Glacier Deep Archive | $0.00099 | $0.19 | 180 d | 40 KB | 12–48 h | Needs lifecycle split |

**Why GLACIER_IR over Standard-IA.** 3.1× cheaper per GiB ($0.76/month vs $2.38/month for the media side), restic supports it natively at upload via `-o s3.storage-class=GLACIER_IR` (no lifecycle gymnastics), and restore is still milliseconds-instant. The 90-day minimum-duration penalty would matter if Restic deleted lots of data frequently — but it doesn't: pack files for photos/music/books/drive are referenced by many snapshots and rarely get orphaned at prune time, and the high-churn case (postgres diff chunks) is small enough in absolute MB that the phantom-storage penalty is pennies/year. The 128 KB minimum-billable-object-size hits small metadata files (`config`, `keys/`, snapshots, locks) — at restic's typical metadata count of a few hundred objects, that's a few MB of "rounded up" billing, also pennies.

**Why not Glacier Flexible / Deep Archive.** Restic's S3 backend (`internal/backend/s3/s3.go`, see `useStorageClass`) treats `GLACIER` and `DEEP_ARCHIVE` as "archive classes": it splits the repo, keeping metadata in STANDARD and only sending data packs to the archive tier. That works, but it adds operational complexity (you can't just point restic at the repo URI — you also need lifecycle rules ensuring the split isn't undone) and restore requires `aws s3api restore-object` thaw requests with 12+ hour waits. For a "we lost both NAS and B2" event, you want instant access to the recovery data, not a thaw queue.

**Why not Standard-IA.** It works fine, just costs 3.1× more for no operational benefit in this workload. The latency difference (Standard-IA ~milliseconds vs GLACIER_IR ~milliseconds) is imperceptible. Pick this only if a future restic upgrade broke GLACIER_IR support, which has never happened.

The rest of this section assumes GLACIER_IR.

### Prerequisites

You need an AWS account, AWS CLI installed on your laptop (`pipx install awscli` or `brew install awscli`), and AWS root access *once* to mint the IAM users below — after which root credentials should not be used again.

### Step S1 — Create the S3 buckets

Two buckets, one per tier. In the AWS S3 console, region **eu-west-1** (Ireland) for GDPR posture and proximity. Settings are identical for both:

| Setting | Value |
|---|---|
| Bucket names | `zanbaldwin-nas-critical-s3` and `zanbaldwin-nas-media-s3` (S3 names are globally unique across all AWS customers) |
| Region | `eu-west-1` |
| Block all public access | **on** |
| Bucket Versioning | **enable** — mirrors the B2-side protection model against version-stomping |
| Default encryption | **SSE-S3** (AES-256, free, transparent) |
| Object Lock | optional — governance mode with 14-day default retention is the equivalent of B2's Object Lock. Can *only* be enabled at bucket creation. |

### Step S2 — Lifecycle rules

Apply to **both** buckets. S3 console → bucket → Management → Lifecycle rules → Create:

**Expire old versions (mirrors B2's 30-day version retention):**

- Rule name: `expire-old-noncurrent-versions`
- Filter: applies to entire bucket
- Action: **Permanently delete noncurrent versions** after **30 days**

This is the S3 equivalent of B2's "Days from hiding to deleting: 30" rule. An attacker with `s3:PutObject` only can still stomp versions; this rule auto-expires the stomped versions after 30 days while keeping the originals recoverable during the window.

No "transition to GLACIER_IR" lifecycle rule is needed. Restic sets the storage class directly at upload via `-o s3.storage-class=GLACIER_IR` (configured in Step S6), so objects land in GLACIER_IR on creation. Lifecycle-based transition would add a per-1000-object transition fee and a ~24-hour Standard-class billing window before the transition runs — both avoidable by setting the class at write time.

### Step S3 — Create the backup IAM users (write-only, live on NAS)

One IAM user per bucket, matching the per-bucket backup-key pattern used on the B2 side. This keeps the blast radius of a single compromised credential limited to one bucket.

**S3a) `backrest-nas-critical-s3`** — Programmatic-only, inline policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::zanbaldwin-nas-critical-s3"
    },
    {
      "Sid": "AllowReadWriteNoDelete",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::zanbaldwin-nas-critical-s3/*"
    }
  ]
}
```

**S3b) `backrest-nas-media-s3`** — Programmatic-only, same policy with the bucket name swapped:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::zanbaldwin-nas-media-s3"
    },
    {
      "Sid": "AllowReadWriteNoDelete",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::zanbaldwin-nas-media-s3/*"
    }
  ]
}
```

Deliberately absent: `s3:DeleteObject`, `s3:DeleteObjectVersion`. This mirrors the B2 backup keys — Backrest can write and read but cannot delete.

Generate an access key for each user. The `AccessKeyId` becomes `AWS_ACCESS_KEY_ID` and `SecretAccessKey` becomes `AWS_SECRET_ACCESS_KEY` in Backrest. **Store both secrets in Bitwarden cloud** before pasting into Backrest — AWS shows them once. The corresponding *admin* user's keys (Step S4) also go on the paper recovery sheet; backup-user keys don't need to since they're re-mintable from the admin user.

### Step S4 — Create the admin IAM user (in Bitwarden cloud + paper recovery sheet, not on NAS)

Single IAM user `admin-s3-prune-restore` with access to **both** buckets:

- Access type: programmatic
- Attach inline policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::zanbaldwin-nas-critical-s3",
        "arn:aws:s3:::zanbaldwin-nas-critical-s3/*",
        "arn:aws:s3:::zanbaldwin-nas-media-s3",
        "arn:aws:s3:::zanbaldwin-nas-media-s3/*"
      ]
    }
  ]
}
```

Generate access keys. Store both in Bitwarden cloud *and* on the paper recovery sheet (these are root-of-trust credentials — they're how you regain access if Bitwarden cloud itself is inaccessible). **Never put these on the NAS.**

### Step S5 — Test the IAM scope (same probe as B2)

Run the probe against **both** buckets, with their respective backup keys. From your laptop:

```bash
aws configure --profile s3-backup-critical
# Enter the backrest-nas-critical-s3 access key + secret

aws configure --profile s3-backup-media
# Enter the backrest-nas-media-s3 access key + secret

# Should succeed (writes go through)
echo "test" | aws s3 cp - s3://zanbaldwin-nas-critical-s3/test/probe.txt \
  --profile s3-backup-critical
echo "test" | aws s3 cp - s3://zanbaldwin-nas-media-s3/test/probe.txt \
  --profile s3-backup-media

# Should FAIL with AccessDenied — proof DeleteObject is denied
aws s3 rm s3://zanbaldwin-nas-critical-s3/test/probe.txt --profile s3-backup-critical
aws s3 rm s3://zanbaldwin-nas-media-s3/test/probe.txt --profile s3-backup-media

# Cross-bucket probe: critical key MUST NOT be able to touch media bucket
# Should FAIL with AccessDenied
aws s3 cp - s3://zanbaldwin-nas-media-s3/test/cross.txt --profile s3-backup-critical <<< "x"

# Confirm with admin key that versioning is on
aws configure --profile s3-admin
# Enter admin-s3-prune-restore credentials

aws s3api list-object-versions \
  --bucket zanbaldwin-nas-critical-s3 \
  --prefix test/probe.txt \
  --profile s3-admin
# Should list one current version
```

If both `aws s3 rm` calls return `AccessDenied` and the cross-bucket probe also fails, the keys are correctly scoped. Clean up the probe files via the admin profile.

### Step S6 — Add the S3 repos to Backrest

In Backrest, add **two** new repos:

| Repo | URI | Restic password | Env vars |
|---|---|---|---|
| `s3-critical` | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/` | Same as the B2 critical repo (enables `restic copy` between them if ever needed) | `AWS_ACCESS_KEY_ID=<backrest-nas-critical-s3 key>`<br>`AWS_SECRET_ACCESS_KEY=<backrest-nas-critical-s3 secret>`<br>`AWS_DEFAULT_REGION=eu-west-1` |
| `s3-media` | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-media-s3/` | Same as the B2 media repo | `AWS_ACCESS_KEY_ID=<backrest-nas-media-s3 key>`<br>`AWS_SECRET_ACCESS_KEY=<backrest-nas-media-s3 secret>`<br>`AWS_DEFAULT_REGION=eu-west-1` |

For each repo, additionally:

- Set restic option `s3.storage-class=GLACIER_IR`. In Backrest this is configured under the repo's "Flags" / "Options" section (the value passed to restic as `-o s3.storage-class=GLACIER_IR`). This is what makes objects land in GLACIER_IR directly on upload — no lifecycle rule required.
- `prunePolicy`: **disabled** — prune from your laptop with the admin key.
- `checkPolicy`: enabled, monthly.

Then **duplicate each B2 plan** to also target the corresponding S3 repo. Same sources, same retention shape, plan IDs suffixed with `-s3` so the two providers are independently identifiable when browsing:

| Plan ID | Repo | Sources | Retention shape | Schedule |
|---|---|---|---|---|
| `critical-s3` | `s3-critical` | same as B2 `critical` | 14d/8w/12m/2y | `30 3 * * *` (after B2 `critical`) |
| `media-s3` | `s3-media` | same as B2 `media` | 7d/4w/6m/1y | `0 3 * * *` (after B2 `media`) |

Each S3 plan fires *after* its B2 counterpart so they're not contending for source-read bandwidth on the NAS. The cascade is: pg_dump 02:00 → media 02:30 → critical + media-s3 03:00 → critical-s3 03:30. For media specifically, the first seed of ~189 GiB will take a few hours on a typical home connection — fine to run once manually on a quiet day; afterwards daily incrementals are minutes.

### Step S7 — Add S3 prune to the monthly ceremony

Append to the monthly script from Step 8. The admin IAM user has access to both buckets, so one env-var setup covers both prune commands:

```bash
# AWS admin credentials (covers both S3 buckets)
export AWS_ACCESS_KEY_ID=<admin-s3-prune-restore access key>
export AWS_SECRET_ACCESS_KEY=<admin-s3-prune-restore secret>
export AWS_DEFAULT_REGION=eu-west-1

# S3 critical mirror — same retention shape as B2 critical
restic -r s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/ forget --prune \
  --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2

# S3 media mirror — same retention shape as B2 media
restic -r s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-media-s3/ forget --prune \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
```

Two commands total, mirroring the B2-side prune. Each S3 repo holds snapshots from a single fat plan (`critical-s3` or `media-s3`), so retention applies cleanly to all snapshots in the repo without `--tag` filtering.

### Step S8 — AWS billing alert

In AWS Billing → Budgets → Create budget:

- Budget type: Cost budget
- Period: monthly
- Amount: **$5/month** (~6× expected spend on the combined critical + media mirrors — alerts early without false positives on minor fluctuation; well below the cost of a runaway upload attack on the write-only keys)
- Alert thresholds: 50%, 80%, 100%
- Notify: your email

AWS also supports more granular S3 service quotas if you want — for a backup workload this single budget is enough.

### Restic and AWS — operational notes

- **Restic versions ≥0.16** handle the AWS S3 backend well. If you're on an older version (Backrest typically bundles current), upgrade before adding the S3 repos.
- **GLACIER_IR is not an "archive" class to restic.** Restic's S3 backend (`internal/backend/s3/s3.go`, `useStorageClass`) special-cases only `GLACIER` and `DEEP_ARCHIVE` — for those, metadata stays in STANDARD and only pack files go to the archive tier. `GLACIER_IR` and `STANDARD_IA` are treated as "regular" classes: the entire repo (including config, keys, index, snapshots, locks) lives in GLACIER_IR. That's fine — instant retrieval means metadata reads work the same as from STANDARD. The only quirk: the 128 KB minimum billable object size applies to every object including small metadata, adding a few MB of "rounded up" storage. Pennies.
- **Independent plans, not `restic copy`.** I considered recommending `restic copy` from B2 to S3 as a downstream mirror, but it couples S3 freshness to B2 availability — if B2 is the very thing that fails, S3 stops getting updates from that point. Independent plans cost a second source-read but give you true provider-redundancy.
- **Restore from S3 in an emergency**: same Restic command as B2, just point at the S3 URI with the admin AWS credentials. GLACIER_IR reads are instant (milliseconds), no thaw delay.
- **First-byte latency is slightly higher on GLACIER_IR** than Standard — adds maybe 50ms per object read. Imperceptible for backup-restore workflows.
- **Prune cost note.** The 90-day GLACIER_IR minimum means any pack file deleted before 90 days pays "phantom" storage for the remainder. In practice this is invisible because (a) Restic's content-defined chunking means very few packs are orphaned at prune time on stable data (photos/music/books/drive), and (b) the high-churn case (postgres diff chunks in critical) is so small in absolute MB that even paying 76 extra days per pruned chunk costs single-digit cents per year. If you ever do a one-off bulk delete (e.g. removing a plan entirely within 90 days of adding it), expect the prune-month bill to spike — that's the only time this surfaces.

## Root of trust — the paper recovery sheet

Every system this strategy relies on (B2, AWS, Bitwarden, the NAS itself) has a credential needed to unlock it. Those credentials all live in Bitwarden cloud for daily use. But Bitwarden cloud has its own failure modes (account suspension, master-password loss, two-factor lockout, Bitwarden Inc going dark), and if Bitwarden is unreachable at the same moment you need to recover the NAS, you're trapped.

The defence against this is a single sheet of paper, written by hand, stored offsite (fireproof safe, safe deposit box, sealed envelope with a trusted family member or solicitor). It's the ultimate root of trust — everything else in the chain is reachable from what's on this sheet, and the sheet itself has properties no cloud service has: it doesn't go offline, doesn't get account-suspended, doesn't require credentials to read, survives EMP and ransomware, can't be exfiltrated remotely.

### What goes on the sheet

A minimal viable list:

- **Bitwarden master password** (or its recovery process — emergency-access contact, biometric unlock device, etc., depending on what you've set up)
- **Bitwarden two-factor recovery code** (Bitwarden gives you one when you enable 2FA — it's the *only* way back in if you lose your second factor)
- **Bitwarden encrypted-export passphrase** (separate from the master password — needed to decrypt the scheduled exports stored in `tank4/secrets/`)
- **Restic repository passwords** for all four repos: B2 critical, B2 media, S3 critical, S3 media
- **B2 admin application key** (keyID + applicationKey)
- **AWS admin IAM user access key** (Access Key ID + Secret Access Key)
- **TrueNAS root or admin password** (or the recovery process if you use SSO)

That's ~10 lines of text. The sheet should fit on a single index card.

### Where it lives

Two copies in two physically separate locations:

1. **Home fireproof safe.** Covers the everyday "I lost my laptop and my phone simultaneously" scenario.
2. **Offsite (safe deposit box, trusted family member, solicitor's safe).** Covers the "house burned down" scenario.

Treat these as you'd treat the only key to your front door. The threat model the paper sheet is *bad* against is "someone physically searches my house and finds it." But that's the same threat model your laptop and your NAS already live under, so you've already accepted it.

### When to update

Rare event. Update when you:

- Rotate any of the listed credentials (Restic password rotation, B2/AWS admin key rotation, Bitwarden master-password change)
- Add a new repo / provider that introduces new root-of-trust secrets
- Change your Bitwarden 2FA method (the recovery code is generated per-2FA-setup)

Realistically: every 1–3 years. Date the sheet so you know which is current.

### What does *not* go on the sheet

Anything reachable from what *is* on the sheet:

- Backrest backup-user keys (re-mintable from the B2/AWS admin keys)
- App service credentials inside the vaults (recoverable by restoring the `critical` plan)
- TrueNAS user passwords for non-admin accounts (re-creatable from admin)

Keeping the sheet short matters: it's easier to update accurately when you only have to write ten lines.

### Verifying the chain works

Once per year, do a tabletop exercise: pretend your NAS is gone, your laptop is gone, and your Bitwarden account is suspended. Walk through recovery using only what's on the paper sheet:

1. Buy/borrow a fresh machine.
2. Install Restic.
3. Use the B2/AWS admin keys (from paper) to authenticate.
4. Use the Restic repo passwords (from paper) to decrypt and restore.
5. Optionally: decrypt a recent Bitwarden-export `.json.enc` from the restored `tank4/secrets/` using the export passphrase (also from paper) to confirm that path also works.

If any step requires information not on the sheet, either the sheet is incomplete or the strategy has another circular dependency. Find it now, not during a real incident.

## Adjacent concerns and unresolved questions

The strategy above covers what gets backed up, how, and to where. These items are *not* in the backup strategy proper but they determine whether the backup strategy actually works in practice. The first three are urgent; the rest can be scheduled.

### Critical (do these soon)

**1. Restic repository passwords stored outside the NAS** — ✓ *Resolved by Bitwarden cloud (primary) + paper recovery sheet (root of trust). See the "Root of trust" section below.*

> **History of this item.** An earlier version of this strategy claimed this was resolved by "dual storage in Vaultwarden + Bitwarden." That was self-deceiving: Vaultwarden was self-hosted *on the NAS*, so losing the NAS lost the keys needed to recover the NAS — a circular dependency. The fix was to drop Vaultwarden, make Bitwarden cloud the primary, and add a physical paper sheet as the ultimate root of trust. The cyclic-dependency bug is the kind of thing that only surfaces during an actual incident, when it's too late.

If `/mnt/fast/apps/backrest/config/backrest.json` is lost AND the passwords aren't elsewhere, every B2/S3 backup becomes a permanently sealed brick — the data is encrypted with that password and no amount of provider-side recovery brings it back. The Bitwarden cloud + paper combination hedges against both NAS loss (use Bitwarden) and Bitwarden account loss (use paper).

**2. Backup-failure notifications** — Wire Backrest's notification hooks (Shoutrrr supports Discord, ntfy, generic webhooks, email). Without this, a failed `pg_dump` cron, a stuck Backrest run, or a B2 capability misconfiguration is invisible until your next restore attempt finds no recent snapshot. Silent failure is the single most common cause of "I had backups, but…" stories. At minimum: notify on `BACKUP_ERROR` and `CHECK_ERROR`; optionally also notify on `BACKUP_SUCCESS` weekly as a heartbeat.

**3. Quarterly restore rehearsal** — Pick one repo, restore to a scratch directory on your laptop, diff against the live source. An untested backup is not a backup. The first rehearsal will surface a problem with your assumptions (wrong path, wrong password store, B2 key missing a capability, retention dropped the snapshot you wanted) — better to find it now than during an actual incident. Calendar reminder for the first Sunday of every March, June, September, December.

### Operational

**4. Postgres ↔ filesystem consistency window**
`pg_dump` runs at 02:00; the `media` plan (which includes Immich's photos source) runs at 02:30 on its own schedule. If a photo upload happens between them, the media backup contains a file the DB snapshot doesn't know about; if a delete happens between them, the inverse. Restore-side reconciliation is messy but doable. Two mitigations:
- (a) accept eventual consistency and document the reconciliation steps in the restore runbook
- (b) chain the backups (pg_dump → media plan) and pause Immich/Forgejo for the window

(a) is the standard homelab choice. Fine if written down.

**5. Restore time and egress**
A full ~189 GiB media-bucket restore from either provider at typical home-connection speeds is **6–12 hours**. B2 includes free egress equal to 3× stored data per month, so one full restore costs nothing extra; multiple restores in one month incur $0.01/GiB after the free allowance. AWS GLACIER_IR egress to internet is billed at standard AWS data-transfer rates plus a $0.03/GiB retrieval fee — a one-off full media restore from S3 would be ~$15-ish all-in, fine for a "we lost everything else" event. Critical-tier restore (1.3 GiB from either B2 or S3) is under 5 minutes and effectively free. Important to internalise *before* a real incident — bulk restore is not instant, and the dial-tone moment of "we're down, how long until we're back?" deserves a known answer.

**6. TrueNAS system config backup**
TrueNAS has its own *system config backup* (Settings → General → Manage Configuration → Download File). Contains user accounts, dataset layout, snapshot tasks, replication tasks, share definitions, NFS exports, app catalog state — none of which is in any data backup. Download after every meaningful config change and attach to a Bitwarden cloud secure note. Tiny file, huge time-saver after a board failure.

**7. ZFS snapshot policy verification**
This strategy assumes ZFS snapshots are the local "human error" protection leg. Verify they're actually scheduled: TrueNAS → Data Protection → Periodic Snapshot Tasks.

Minimum coverage:
- All `tank4/*` data datasets (`secrets`, `backups`, `code`, `books`, `photos`, `music`, `drive`) — daily, 30-day retention
- `fast/apps` — daily, 30-day retention (covers app config that the `critical` plan also offsites via its `/mnt/fast/apps` source)

Without these, B2's daily-granularity is your *only* "I deleted that yesterday" recovery, which is worse than what ZFS can give you locally for free.

**8. Disaster-recovery runbook (separate document)**
The compose files in `~/.dotfiles/nas/apps/` are most of the recovery, but the deployment process itself isn't captured anywhere — where they're symlinked on the NAS, what user runs `docker compose up`, any systemd units involved, the order in which services come up. A one-page runbook in `~/.dotfiles/nas/RESTORE.md` along the lines of:

```
1. TrueNAS install on replacement hardware, import TrueNAS config from the
   secure note attached in Bitwarden cloud
2. Import ZFS pools (or restore media from B2 if pools are lost too)
3. Retrieve B2 + S3 admin keys and Restic repo passwords from Bitwarden cloud
   (primary). If Bitwarden cloud is also unavailable, use the paper recovery
   sheet (root of trust) instead.
4. Restic-restore the latest `critical` snapshot, `--include /mnt/tank4/secrets`
   → recovers secret files
5. Restic-restore the same snapshot, `--include /mnt/tank4/backups/postgres`
   → run pg_restore against postgres
6. Restic-restore the same snapshot, `--include /mnt/fast/apps`
   → app configs + LE certs in place
7. Clone dotfiles repo from Forgejo (or from local copy if Forgejo is down)
8. docker compose up -d on each compose.*.yaml in dependency order
9. Restic-restore the latest `media` snapshot, with `--include` per source as
   needed (photos/music/books/drive)
10. Verify: tailscale up, NPM proxy hosts, Immich, Forgejo
11. Re-issue Let's Encrypt certs if proxy/certs was lost (cert state was
    included in step 6's apps restore)
```

Both tiers can come from either B2 or S3 — pick whichever is reachable. With both providers in play, the only fully-dark scenario requires simultaneous failure of B2 + AWS.

…closes the gap a stressed-out future-you will care about most.

### Threat-model gaps not closed by the two-key pattern

**9. NAS compromise = full read access to all backups**
The two-key pattern prevents an attacker on the NAS from *destroying* the offsite. It does NOT prevent them from downloading and decrypting every backup, because the Restic password is in `backrest.json` next to the B2 key. If your threat model includes "someone reads my photos", this isn't solved. Mitigation paths exist (HSM-stored keys, REST-server append-only fronting B2, separate encrypting filesystem) but they're well outside the homelab norm and add significant ops complexity.

**10. Backrest WebUI authentication hardening**
`backup.lan.zanbaldwin.com` has a single bcrypt user. UI compromise = control of all backup jobs (pause, modify retention, exfiltrate snapshots, trigger restore-as-attacker). Two improvements:
- Verify the NPM proxy host has an Access List restricting access to LAN + Tailscale CIDRs only, not exposing to the public internet
- Confirm the user password is long, unique, and stored in Bitwarden cloud — not reused from anywhere else

### Smaller things worth knowing

**11. B2 bucket names are globally unique** across all Backblaze customers. `zanbaldwin-nas-critical` is probably free; if it's taken, suffix with a random string. The name change has no operational impact beyond the URI in `backrest.json`.

**12. B2 region** — confirm during migration that the bucket is in `eu-central-003` (Frankfurt), not US-West. Affects egress latency, restore speed, and GDPR posture.

**13. Restic version skew** — Backrest bundles a specific Restic version. If you upgrade Backrest and the new version bumps the repository format, older Restic clients can't read until they also upgrade. Not an issue in steady state, but if you ever restore from a stale machine, upgrade its Restic before connecting to a recently-touched repo.

**14. Don't dismiss the `fast/apps` source as low-value** — Calibre tagging/metadata in `fast/apps/calibre/` and Navidrome's play counts/playlists/listen history in `fast/apps/navidrome/navidrome.db` are years of accumulated state. The underlying media survives without them, but losing the `fast/apps` source from the `critical` plan means losing all that contextual data even though "nothing is broken". Functional + sentimental value, not "skippable".

**15. This document needs to live somewhere durable** — currently in `/tmp/nas/BACKUP_STRATEGY.md` on your laptop. Move it into `~/.dotfiles/nas/` (so it's in the Forgejo repo → in `tank4/code` → in the backup → in B2) before the next reboot, otherwise the entire planning conversation is one `rm /tmp` away from being gone.

## Smaller follow-up items (file these as TODOs)

1. **Local "copy 2" of the 3-2-1.** With B2 + S3 mirroring both tiers, you now have two independent offsite copies of *everything*. The remaining gap is local: ZFS + RAID-Z on `tank4` is one local copy + redundancy, but still one disk subsystem in one chassis. A periodic `restic copy` of either repo to a USB-attached disk or a second ZFS pool gives a true second medium locally. Less urgent now that S3 mirrors media too, but worth raising once the offsite story is settled.
2. **Stale `tank4/backups/postgres.sql`** (339 MB) — delete via TrueNAS WebUI.
3. **`fast/home/zan`** is just the default shell skel (bashrc/profile/bash_logout). If you ever actually use it, add `/mnt/fast/home/zan` to the `critical` plan's source list.
