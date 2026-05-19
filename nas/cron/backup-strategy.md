# NAS Backup Strategy

Planning document. No changes have been made to the NAS or to `backrest.json`.

## Goals (confirmed)

1. **Hardware redundancy / offsite (3-2-1):** Backblaze B2 is the primary offsite for everything. AWS S3 (Glacier-class) is a secondary offsite for the *critical* tier — provider-redundancy on the data that would actually disrupt life if lost. ZFS on `tank4` + TrueNAS snapshots cover local redundancy/human-error.
2. **Protection against credential theft / ransomware on the NAS:** The B2 and S3 credentials sitting on the NAS must not be able to *delete* what's already backed up.
3. **Protection against human error:** ZFS snapshots are the first line; B2/S3 retention is the second.
4. **Moderate retention** at B2 list pricing; longer retention for critical, shorter for media.
5. **Two tiers, split by life-impact:** *critical* = losing this causes ongoing real-world friction (passwords, app state, code, documents). *media* = losing this is painful and irreplaceable in personal terms but you survive without it (photos, music, books, drive).

## Diagnosis: what the current config actually covers

The Backrest config currently has two plans:

| Plan | Source | Backed up? |
|---|---|---|
| `B2-Class1` | `/mnt/tank4/class1` | Yes |
| `B2-Postgres` | `/mnt/tank4/backups/postgres` | Yes |

Compared to what's on the NAS, the following is **not currently backed up**:

| Path | Size | Tier (new) | Notes |
|---|---|---|---|
| `class2/photos` | 69 GB | media | Immich originals. |
| `class2/music` | 103 GB | media | |
| `class2/code` | 162 MB | critical | Forgejo bare repos. |
| `class2/documents` | 443 MB | critical | Assumes financial/legal docs present. |
| `class2/drive` | 4.9 GB | media | General file dump. |
| `class2/backups` | 339 MB | n/a | Stale `postgres.sql` leftover — delete via WebUI. |
| `fast/apps/*` | ~32 MB | critical | NPM config + LE certs, Navidrome DB, Memos files (DB in Postgres), Calibre-Web, Tailscale state. |
| `class3/forgejo` | 375 K | skipped | Per your decision. See "Class3 risk note" below. |
| `class3/immich` | 24 G | skipped | Regenerable (thumbs 7.5G, encoded-video 16G, upload staging 646M). |

Together this is ~178 GB of currently-unprotected data. At B2 list price (~$0.006/GiB-month) that's about **$1.07/month** of B2 storage, plus a small overhead for retention.

## Recommended structure

**Two buckets, split by life-impact**: *critical* (things that disrupt life if lost) vs *media* (things that hurt to lose but you survive). **One Restic repo per bucket** with Backrest plans tagging snapshots by source. **Two-key Restic pattern** on each bucket. **Critical mirrored to AWS S3 Glacier** as a second offsite. **Skip all of class3.**

### Buckets

```
zanbaldwin-nas-critical    ← ~1.3 GiB, life-impact data. Mirrored to B2 + S3 Glacier.
zanbaldwin-nas-media       ← ~189 GiB, irreplaceable but survivable. B2 only.
```

The S3 mirror exists *only* for the critical tier. Media's volume makes a second provider expensive, and the recovery path for media is "annoying but possible from other sources" (phones for photos, streaming for music, re-acquisition for books), so a single offsite is proportionate. Critical data — passwords, app state, code, financial documents — has no "other source"; provider-redundancy is where it earns its keep.

### Restic repos

**One repo per bucket, not one per data class.** Backrest plans tag their snapshots with the plan ID; retention is applied per-tag at prune time using `restic forget --tag <name>`. This collapses what would otherwise be 8 separate Restic repos down to 2 — same per-plan retention behavior, far less ops surface, less repo-state to maintain, simpler restore mental model.

| Bucket | Repo URI | Plans (snapshot tags) | Approx. size |
|---|---|---|---:|
| `zanbaldwin-nas-critical` | `b2:zanbaldwin-nas-critical:/` | `secrets`, `postgres`, `code`, `documents`, `apps` | ~1.3 GiB |
| `zanbaldwin-nas-media` | `b2:zanbaldwin-nas-media:/` | `books`, `photos`, `music`, `drive` | ~189 GiB |
| `zanbaldwin-nas-critical-s3` *(mirror)* | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/` | same as B2 critical | ~1.3 GiB |

Trade-off vs the previous "8 repos" idea: backups within one repo are serialised by Restic's repo lock (only one writer at a time). The eight plans across critical would all queue behind each other if they fired simultaneously. At your scale this adds maybe 30–60s of total wall-clock; not material. The blast radius from repository corruption goes up — losing one repo loses one bucket's worth — but B2 versioning + the 30-day lifecycle rule mitigates that, and the S3 mirror on critical protects you against catastrophic loss of the bucket itself.

### What goes in each plan

**Critical plans (`zanbaldwin-nas-critical`):**

| Plan tag | Source | Why critical |
|---|---|---|
| `secrets` | `/mnt/tank4/class1/secrets` | Postgres root password, B2 keys, Cloudflare API key, Tailscale auth key, Vaultwarden attachments/sends, Paperless secrets. |
| `postgres` | `/mnt/tank4/class1/backups/postgres` | All app DB dumps — Vaultwarden (now Postgres-backed), Forgejo (issues/PRs/users), Immich (tags/albums), Memos. Losing this is losing every app's functional state. |
| `code` | `/mnt/tank4/class2/code` | Forgejo bare repos. If Forgejo is the only home for any repo (no GitHub/Codeberg mirror), this *is* the source of truth. |
| `documents` | `/mnt/tank4/class2/documents` | Tax records, contracts, IDs, scanned legal docs. Assumed to contain financial/legal-impact content; if yours doesn't, downgrade to media. |
| `apps` | `/mnt/fast/apps` (excludes below) | NPM proxy DB + Let's Encrypt cert state (avoids LE rate-limit pain on rebuild), Tailscale node key, Calibre/Navidrome/Memos config and per-app file state. |

**Media plans (`zanbaldwin-nas-media`):**

| Plan tag | Source | Why media |
|---|---|---|
| `books` | `/mnt/tank4/class1/books` | Calibre library — books are findable from origin. The Calibre metadata layer (tags, shelves) lives in `apps`. |
| `photos` | `/mnt/tank4/class2/photos` *plus* `/mnt/tank4/class1/photos` if populated | Immich library. Irreplaceable personally; survivable functionally. Devices typically also retain originals. |
| `music` | `/mnt/tank4/class2/music` | Replaceable in principle (streaming/re-rip), prohibitive effort cost. |
| `drive` | `/mnt/tank4/class2/drive` | General file dump. |

### Retention shapes (applied per snapshot tag)

Critical plans get long retention — you want the ability to roll back six months when you discover something was quietly corrupted:

```
secrets, postgres, code, documents, apps:
  daily=14   weekly=8   monthly=12   yearly=2
```

Media plans get shorter retention — large data with low churn means deep history is mostly redundant with the previous snapshot:

```
photos, music:
  daily=7    weekly=4   monthly=3    yearly=1
books, drive:
  daily=7    weekly=4   monthly=6    yearly=1
```

The monthly prune ceremony (later section) applies these per-tag.

### Two-key pattern on both providers, S3 mirror running independently

Each of the three repos (B2 critical, B2 media, S3 critical) has its own write-only backup credential lives in Backrest, and its own admin credential lives in Vaultwarden. The S3 mirror runs as an *independent* second plan against the same sources — not as a downstream `restic copy` from B2. The reason: independent plans survive single-provider outages. If B2 is unreachable when the schedule fires, S3 still gets a fresh snapshot, and vice versa.

Cost of independence: source files are read twice during the backup window (once per provider). At critical's ~1.3 GiB scale and overnight scheduling, irrelevant.

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

### Admin key — kept in Vaultwarden, *not* stored on the NAS

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
   export B2_ACCOUNT_ID=...   # admin key
   export B2_ACCOUNT_KEY=...
   restic -r b2:zanbaldwin-nas-critical:/postgres forget --prune \
       --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2
   # repeat per repo
   ```
   Trade: requires monthly discipline. Win: NAS compromise is structurally incapable of damaging the offsite.

2. **Hybrid** — Run a *second* Backrest instance on your desktop pointed at the same repos with the admin key, with the prune schedule enabled there and the backup schedule disabled. Same end result, less manual ceremony. Cost: another small piece of infrastructure to maintain.

Either way: **remove `prunePolicy` from the NAS Backrest config** — or set it to never run. Leaving it scheduled there with a write-only key just means error emails forever.

`checkPolicy` on the NAS-side is fine to keep (it only reads).

## Postgres backup — host cron, not Backrest hook

### Why host cron and not a Backrest pre-backup hook

Backrest runs as a Docker container. To run `pg_dump` against the postgres container, it would need to either (a) `docker exec` from inside Backrest — requires mounting the Docker socket into Backrest, which is root-equivalent on the host and silently undoes the entire containerization-isolation story; or (b) call a webhook on the host that runs pg_dump — extra moving part, another service to harden.

The clean answer: **host cron does the dump; Backrest backs up the resulting file.** This is what you already have today, just with a few refinements:

1. **Per-database dumps in custom format** for selective restore. Custom format (`-Fc`) is restored with `pg_restore` and supports per-table extraction:

   ```bash
   #!/usr/bin/env bash
   # /usr/local/bin/pg-dump-job.sh
   set -euo pipefail
   OUT=/mnt/tank4/class1/backups/postgres
   TMP=$(mktemp -d)
   trap "rm -rf '$TMP'" EXIT

   for db in main forgejo immich memos vaultwarden; do
     docker exec -i postgres-postgres-1 \
       pg_dump -Fc -U main -d "$db" > "$TMP/${db}.dump"
   done

   # Globals (roles, tablespaces) for a clean rebuild
   docker exec -i postgres-postgres-1 \
     pg_dumpall -U main --globals-only > "$TMP/globals.sql"

   # Atomic rotate — partial writes won't pollute the backup source
   mv "$TMP"/*.dump "$TMP"/globals.sql "$OUT/"

   # Notify on failure (cron will mail or we can pipe to ntfy)
   ```

   Host crontab:
   ```cron
   MAILTO=root
   0 2 * * * root /usr/local/bin/pg-dump-job.sh || \
     curl -fsS -d "pg_dump failed on $(hostname)" https://ntfy.sh/your-private-topic
   ```

   Schedule the Backrest `postgres` plan for 03:00 — after the dump completes but before the rest of the critical plans run at 02:30… wait, swap: dump at 02:00, Backrest critical plans at 03:00 so they all pick up the freshly-rotated files.

2. **Move the dump location** from `/mnt/tank4/backups/postgres/` (un-classed top-level dir) to `/mnt/tank4/class1/backups/postgres/` for consistency. With the new structure this means the `postgres` plan source path is `/mnt/tank4/class1/backups/postgres` (already reflected in the plan table in Step 6).

3. **The stale `/mnt/tank4/class2/backups/postgres.sql`** (339 MB) should be deleted via the TrueNAS WebUI.

### Same pattern for SQLite databases

For Navidrome's SQLite (`fast/apps/navidrome/navidrome.db`), use the same host-cron approach with SQLite's atomic `.backup` command:

```bash
# Add to pg-dump-job.sh or run as a separate host cron
sqlite3 /mnt/fast/apps/navidrome/navidrome.db \
  ".backup '/mnt/fast/apps/navidrome/navidrome.db.backup'"
```

Then add `navidrome.db` (the live one — Backrest could capture mid-write) and `navidrome.db-wal`, `navidrome.db-shm` to the `apps` plan's exclude list. The `.backup` file (consistent snapshot) gets included.

Note: with Vaultwarden now Postgres-backed (per the recent `compose.vault.yaml` change), its SQLite database is no longer in play — `class1/secrets/vault/` holds attachments and Sends but the actual user/password data lives in postgres → covered by `pg_dump`.

## Excludes for the `apps` plan

Most of `fast/apps/*` is small config — back it up. But three things should be excluded:

- `/mnt/fast/apps/postgres/**` — live DB data dir. The authoritative copy is the pg_dump. Backing up the live data dir = inconsistent snapshots and wasted space.
- `/mnt/fast/apps/paperless/index/**` — regenerable search index.
- `/mnt/fast/apps/paperless/log/**` — logs.
- `/mnt/fast/apps/backrest/cache/**` — Restic local cache, regenerable.

Existing excludes on the class1 plan (`**/cache`, `**/.cache`, `**/Cache`, `**/*.tmp`, `**/thumbs`, `**/node_modules`, `**/.DS_Store`, `**/.Spotlight-V100`, `**/.Trashes`) are sensible — reuse the same list on every plan.

## Class3 risk note (informational, not a recommendation against your decision)

You chose to skip all of `class3`. Concretely that means after a total-disaster restore:

- **Forgejo SSH host keys** in `/mnt/tank4/class3/forgejo/ssh/` are lost → every existing clone gets `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED` until the user re-pins. Annoying, recoverable.
- **Forgejo `app.ini` secrets** (session keys, OAuth client secrets, JWT signing) are lost → everyone re-logs-in once. OAuth integrations to external services need their client secrets re-issued.
- **Forgejo wiki / attachments / LFS** in `class3/forgejo/git/lfs/` are lost. Repo commits survive (those are on `class2/code`), but anything stored as an attachment or LFS pointer does not.
- **Immich avatars** (`class3/immich/profile`) lost.
- **Immich in-flight uploads** (`class3/immich/upload`) — anything not yet template-moved to `class2/photos`. Usually a handful of files per recent sync.
- **Immich thumbs / encoded-video** — regenerate automatically over hours/days of CPU+GPU time.

If any of those bullets sting more than expected, the surgical fix is to add a single extra source `/mnt/fast/apps`-style backup plan covering only `class3/forgejo` (~375 KB) and skip the Immich-derived dirs. It's a 375 KB add at trivial cost.

## Cost projection

### Empirical baseline

You're currently billed **$0.06 USD over ~5 months** for 12.6 GiB in `zanbaldwin-nas-backup`. That works out to **~$0.012/month** for the existing class1 + postgres backup. The reason it's so cheap is the account-wide **10 GB free tier**: only ~2.6 GiB is actually billable, giving an effective rate of ~$0.004/GiB-month on the current setup (where the free tier covers 79% of stored data).

The free tier doesn't scale — once total stored data clears 10 GB, you pay list price (**$0.006/GiB-month**, ~$6/TB) for everything above it. Transactions (uploads, downloads, list calls) are billed separately at trivial rates for a backup workload (under $0.01/month at this scale).

### Projected cost of the full strategy

Per-tier breakdown using B2 list price ($0.006/GiB-month) past the 10 GB free tier, and AWS S3 Standard-IA ($0.0125/GiB-month) for the S3 mirror:

| Provider | Bucket | Tier | Approx size | $/month |
|---|---|---|---:|---:|
| B2 | `zanbaldwin-nas-critical` | critical | 1.3 GiB | $0.008 |
| B2 | `zanbaldwin-nas-media` | media | 189 GiB | $1.07 |
| AWS S3 | `zanbaldwin-nas-critical-s3` | critical mirror | 1.3 GiB | $0.016 |
| - Free tier (B2 only, 10 GiB) | | | -10 GiB | -$0.06 |
| **Base total** | | | **~191 GiB** | **~$1.04/month** |

Plus retention overhead (typically +15–25% on Restic repos with active churn, much less on the immutable repos): realistic ongoing total **$1.25–$1.45/month**, dominated entirely by media (`music` + `photos`).

The S3 mirror is *essentially free* — $0.016/month at Standard-IA, ~$0.001/month if you opt for Deep Archive — and gives you provider-redundancy on the only data that genuinely can't be lost. Cost is not why you'd hesitate to add it.

Note: if you enable Object Lock with a 14-day default retention, pruned data keeps being billed until its lock expires. For your retention shapes that adds maybe 1–2 GiB of "ghost storage" at any given time — about $0.01/month. Not material.

### Cost over the first year

Initial seed uploads are free on both B2 and AWS S3. Once seeded, expect:

- Month 1–2: ~$1.30/month as indices settle
- Steady state: ~$1.40/month, drifting up by maybe $0.05/month per year as photos/music grow
- Version-stomping incident (if it happens): temporary doubling for the 30-day version retention window. Worst case caps at ~$2.50/month for one month.

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

You have an existing `zanbaldwin-nas-backup` with two Restic repos (`/class1`, `/database/postgres`) and 12.6 GiB of data. Since the new layout uses a *different repo structure* (one repo per bucket with tagged plans, not multiple repos at sub-paths), there's no clean way to "repurpose" the existing bucket without ending up with mixed-layout cruft. **Recommended path: clean slate.**

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
b2 application-key create \
  --bucket zanbaldwin-nas-critical \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,readBucketEncryption \
  backrest-nas-critical
```

```bash
b2 application-key create \
  --bucket zanbaldwin-nas-media \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,readBucketEncryption \
  backrest-nas-media
```

Each command prints a `keyID` and `applicationKey` **once**. Capture both. The `keyID` is what becomes `B2_ACCOUNT_ID`; the `applicationKey` is what becomes `B2_ACCOUNT_KEY`. These are what go into the Backrest UI's repo configuration (one set per repo, scoped to its bucket).

**4b) Admin key (lives in Vaultwarden, *not* on the NAS)**

One key with full access to both buckets. If you went with Option B (Object Lock), also include `bypassGovernance` so prune can override the lock on legitimately-expired retentions:

```bash
b2 application-key create \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,deleteFiles,readBuckets,writeBuckets,readBucketEncryption,writeBucketEncryption,readBucketReplications,writeBucketReplications,readBucketRetentions,writeBucketRetentions,readFileRetentions,writeFileRetentions,readFileLegalHolds,writeFileLegalHolds,bypassGovernance,listAllBucketNames \
  admin-prune-restore
```

(Drop `bypassGovernance` and the file-retention caps if you didn't enable Object Lock.)

Capture the output. Store both `keyID` and `applicationKey` as a Vaultwarden secure note, not in any config file on the NAS.

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

### Step 6 — Update Backrest

In the Backrest web UI (`backup.lan.zanbaldwin.com`):

**Add the two B2 repos** (S3 repo added in a separate section below):

| Repo | URI | Env vars |
|---|---|---|
| `b2-critical` | `b2:zanbaldwin-nas-critical:/` | `B2_ACCOUNT_ID` + `B2_ACCOUNT_KEY` from the `backrest-nas-critical` key |
| `b2-media` | `b2:zanbaldwin-nas-media:/` | `B2_ACCOUNT_ID` + `B2_ACCOUNT_KEY` from the `backrest-nas-media` key |

For each new repo:
- Set a strong Restic password (different for each repo). **Store both passwords in Vaultwarden + Bitwarden** before doing anything else.
- **Remove or disable** the `prunePolicy` on the repo — you'll prune from your laptop with the admin key. The backup key cannot delete, so leaving prune enabled produces error notifications forever.
- `checkPolicy` can stay — it only reads.
- Let Backrest run `restic init` on first save.

**Add plans:**

For the `b2-critical` repo, add 5 plans (one per source). Each plan automatically tags its snapshots with the plan ID:

| Plan ID | Sources | Retention shape | Schedule |
|---|---|---|---|
| `secrets` | `/mnt/tank4/class1/secrets` | 14d/8w/12m/2y | `30 2 * * *` |
| `postgres` | `/mnt/tank4/class1/backups/postgres` | 14d/8w/12m/2y | `0 3 * * *` (after pg_dump cron) |
| `code` | `/mnt/tank4/class2/code` | 14d/8w/12m/2y | `30 2 * * *` |
| `documents` | `/mnt/tank4/class2/documents` | 14d/8w/12m/2y | `30 2 * * *` |
| `apps` | `/mnt/fast/apps` (excludes below) | 14d/8w/12m/2y | `30 2 * * *` |

For the `b2-media` repo, add 4 plans:

| Plan ID | Sources | Retention shape | Schedule |
|---|---|---|---|
| `books` | `/mnt/tank4/class1/books` | 7d/4w/6m/1y | `30 2 * * *` |
| `photos` | `/mnt/tank4/class2/photos` (+ `/mnt/tank4/class1/photos` if populated) | 7d/4w/3m/1y | `30 2 * * *` |
| `music` | `/mnt/tank4/class2/music` | 7d/4w/3m/1y | `30 2 * * *` |
| `drive` | `/mnt/tank4/class2/drive` | 7d/4w/6m/1y | `30 2 * * *` |

Within a single repo, plans queue behind each other on the repo lock — that's fine, total overnight wall-clock is still well under the schedule window.

Once the new backups verify successfully (a snapshot landed in each plan), delete the old `B2-Class1` and `B2-Postgres` plans/repos and the old `zanbaldwin-nas-backup` bucket.

### Step 7 — Rotate / revoke the old master-keyed access

Once everything is migrated and verified:

In the B2 console: **App Keys → [old master/full key used in current `backrest.json`] → Delete**.

This removes the old single-credential blast-radius from the system. The master account key (the one tied to your login) stays — you'll need it occasionally to mint new keys — but it should never live in any config file.

### Step 8 — Monthly prune ceremony (from your laptop)

Add a calendar reminder for the first Sunday of each month. Two repos to prune on B2; S3 critical mirror is pruned in the S3 section below.

```bash
# Authorize with B2 admin key
export B2_ACCOUNT_ID=<admin keyID>
export B2_ACCOUNT_KEY=<admin applicationKey>

# Critical repo: all plans share the same retention shape.
# --group-by tag means snapshots are partitioned by their tag,
# and the policy is applied independently to each group.
restic -r b2:zanbaldwin-nas-critical: forget --prune \
  --group-by tag \
  --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2

# Media repo: per-tag retention because shapes differ.
# Forget marks snapshots for removal but doesn't free space until prune.
restic -r b2:zanbaldwin-nas-media: forget --tag photos \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --keep-yearly 1
restic -r b2:zanbaldwin-nas-media: forget --tag music \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --keep-yearly 1
restic -r b2:zanbaldwin-nas-media: forget --tag books \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
restic -r b2:zanbaldwin-nas-media: forget --tag drive \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1

# Single prune pass over the media repo (cheaper than four prunes)
restic -r b2:zanbaldwin-nas-media: prune
```

Restic's repo passwords (separate from the B2 keys) live in `backrest.json` on the NAS — they're also stored in Vaultwarden + Bitwarden per "Adjacent concerns #1". The Restic password is what actually encrypts the backup data; the B2 key is only access control on the storage side.

## AWS S3 mirror for the critical bucket — step by step

The critical tier gets a second offsite on AWS S3, giving you provider-redundancy: if Backblaze is unreachable (account suspension, regional outage, billing dispute), AWS still has a full critical-tier snapshot history. The media tier stays on B2 only.

### Pick a storage class

For ~1.3 GiB at AWS S3 pricing in `eu-west-1` (Ireland):

| Class | $/GiB-mo | Monthly | Min duration | Retrieval time | Retrieval $ | Restic compat |
|---|---:|---:|---|---|---|---|
| Standard | $0.023 | $0.030 | none | instant | egress only | Native |
| **Standard-IA** *(recommended)* | $0.0125 | $0.016 | 30 d | instant | $0.01/GiB | Native |
| Glacier Instant Retrieval | $0.004 | $0.005 | 90 d | instant | $0.03/GiB | Native |
| Glacier Flexible Retrieval | $0.0036 | $0.005 | 90 d | 1 min–5 h | $0.03/GiB | Needs lifecycle |
| Glacier Deep Archive | $0.00099 | $0.001 | 180 d | 12–48 h | $0.02/GiB | Needs lifecycle |

At this data size the absolute storage costs are noise — all options are under $0.04/month. The real choice is operational:

- **Standard-IA (recommended).** Simplest. Restic works natively, restore is instant in an emergency, 30-day minimum is shorter than the smallest "daily" bucket in the critical retention shape. $0.016/month for 1.3 GiB.
- **Glacier IR.** Cheaper. Restic native. 90-day minimum amplifies cost on the daily-churned `postgres` dump (each daily dump pays storage for 90 days even when pruned at 14). At 1.3 GiB this is still pennies; worth knowing.
- **Glacier Deep Archive.** Cheapest in absolute terms, but requires careful S3 lifecycle policies to keep Restic's metadata (`config`, `keys/`, `index/`, `snapshots/`, `locks/`) in Standard/IA while moving only `data/` packs to Deep Archive. Otherwise every Restic operation fails to read its own metadata. Restore from Deep Archive needs an `aws s3api restore-object` thaw request and 12–48 hours wait. Fine for "the apocalypse happened to both NAS and B2"; not fine for "I need a password from a 2-month-old snapshot at 2 AM".

**Recommendation: Standard-IA.** The $0.015/month savings vs Deep Archive isn't worth the operational complexity and the loss of instant restore.

The rest of this section assumes Standard-IA. If you choose Deep Archive, the IAM and Backrest setup is the same; only Step S2 changes (lifecycle rules become object-prefix-aware).

### Prerequisites

You need an AWS account, AWS CLI installed on your laptop (`pipx install awscli` or `brew install awscli`), and AWS root access *once* to mint the IAM users below — after which root credentials should not be used again.

### Step S1 — Create the S3 bucket

In the AWS S3 console, region **eu-west-1** (Ireland) for GDPR posture and proximity:

| Setting | Value |
|---|---|
| Bucket name | `zanbaldwin-nas-critical-s3` (S3 names are globally unique across all AWS customers) |
| Region | `eu-west-1` |
| Block all public access | **on** |
| Bucket Versioning | **enable** — mirrors the B2-side protection model against version-stomping |
| Default encryption | **SSE-S3** (AES-256, free, transparent) |
| Object Lock | optional — governance mode with 14-day default retention is the equivalent of B2's Object Lock. Can *only* be enabled at bucket creation. |

### Step S2 — Lifecycle rules

S3 console → bucket → Management → Lifecycle rules → Create:

**Rule 1 — Transition to Standard-IA:**

- Rule name: `transition-to-standard-ia`
- Filter: applies to entire bucket
- Action: **Transition current versions** of objects → **Standard-IA** after **0 days**

This makes Standard-IA the effective default storage class. Objects written by Restic land there immediately on creation (transitions count from upload time).

**Rule 2 — Expire old versions (mirrors B2's 30-day version retention):**

- Rule name: `expire-old-noncurrent-versions`
- Action: **Permanently delete noncurrent versions** after **30 days**

This is the S3 equivalent of B2's "Days from hiding to deleting: 30" rule. An attacker with `s3:PutObject` only can still stomp versions; this rule auto-expires the stomped versions after 30 days while keeping the originals recoverable during the window.

### Step S3 — Create the backup IAM user (write-only, lives on NAS)

In IAM → Users → Create user `backrest-nas-critical-s3`:

- Access type: **Programmatic only** (no console password)
- Attach inline policy:

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

Deliberately absent: `s3:DeleteObject`, `s3:DeleteObjectVersion`. This mirrors the B2 backup key — Backrest can write and read but cannot delete.

Generate an access key for this user. The `AccessKeyId` becomes `AWS_ACCESS_KEY_ID` and `SecretAccessKey` becomes `AWS_SECRET_ACCESS_KEY` in Backrest. **Store the secret in Vaultwarden + Bitwarden** before pasting into Backrest — AWS shows it once.

### Step S4 — Create the admin IAM user (in Vaultwarden, not on NAS)

Second IAM user `admin-s3-prune-restore`:

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
        "arn:aws:s3:::zanbaldwin-nas-critical-s3/*"
      ]
    }
  ]
}
```

Generate access keys. Store both in Vaultwarden + Bitwarden. **Never put these on the NAS.**

### Step S5 — Test the IAM scope (same probe as B2)

From your laptop:

```bash
aws configure --profile s3-backup-nas
# Enter the backrest-nas-critical-s3 access key + secret

# Should succeed
echo "test" | aws s3 cp - s3://zanbaldwin-nas-critical-s3/test/probe.txt \
  --profile s3-backup-nas

# Should FAIL with AccessDenied — proof DeleteObject is denied
aws s3 rm s3://zanbaldwin-nas-critical-s3/test/probe.txt --profile s3-backup-nas

# Confirm with admin key that versioning is on
aws configure --profile s3-admin
# Enter admin-s3-prune-restore credentials

aws s3api list-object-versions \
  --bucket zanbaldwin-nas-critical-s3 \
  --prefix test/probe.txt \
  --profile s3-admin
# Should list one current version
```

If the `aws s3 rm` returns `AccessDenied`, the backup key is correctly scoped. Clean up via the admin profile.

### Step S6 — Add the S3 repo to Backrest

In Backrest, add a new repo:

| Field | Value |
|---|---|
| Repo URI | `s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/` |
| Restic password | **Use the same password as the B2 critical repo.** If you ever want to `restic copy` between them in either direction, the password must match. |
| Env vars | `AWS_ACCESS_KEY_ID=<backup user access key>`<br>`AWS_SECRET_ACCESS_KEY=<backup user secret>`<br>`AWS_DEFAULT_REGION=eu-west-1` |
| `prunePolicy` | **disabled** — prune from your laptop with the admin key |
| `checkPolicy` | enabled, monthly |

Then **duplicate each critical plan** to also target this repo. Same sources, same retention shape, same tag — only the `repo` field differs:

| Plan ID | Source | Repo |
|---|---|---|
| `secrets-s3` | `/mnt/tank4/class1/secrets` | `s3-critical` |
| `postgres-s3` | `/mnt/tank4/class1/backups/postgres` | `s3-critical` |
| `code-s3` | `/mnt/tank4/class2/code` | `s3-critical` |
| `documents-s3` | `/mnt/tank4/class2/documents` | `s3-critical` |
| `apps-s3` | `/mnt/fast/apps` | `s3-critical` |

Schedule them to run *after* the B2 plans complete (e.g. B2 at 02:30, S3 at 03:30) so they're not contending for source-read bandwidth.

The `-s3` suffix in the tag means S3 snapshots are independently identifiable from B2 snapshots if you ever browse the repos. Prune treats each tag independently, which is what you want.

### Step S7 — Add S3 prune to the monthly ceremony

Append to the monthly script from Step 8:

```bash
# S3 critical mirror — same retention shape as B2 critical
export AWS_ACCESS_KEY_ID=<admin-s3-prune-restore access key>
export AWS_SECRET_ACCESS_KEY=<admin-s3-prune-restore secret>
export AWS_DEFAULT_REGION=eu-west-1

restic -r s3:s3.eu-west-1.amazonaws.com/zanbaldwin-nas-critical-s3/ \
  forget --prune \
  --group-by tag \
  --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2
```

### Step S8 — AWS billing alert

In AWS Billing → Budgets → Create budget:

- Budget type: Cost budget
- Period: monthly
- Amount: **$2/month** (10× expected spend on the critical mirror — alerts you early without false positives on minor fluctuation)
- Alert thresholds: 50%, 80%, 100%
- Notify: your email

AWS also supports more granular S3 service quotas if you want — for a backup workload this single budget is enough.

### Restic and AWS — operational notes

- **Restic versions ≥0.16** handle the AWS S3 backend well. If you're on an older version (Backrest typically bundles current), upgrade before adding the S3 repo.
- **Independent plans, not `restic copy`.** I considered recommending `restic copy` from B2 to S3 as a downstream mirror, but it couples S3 freshness to B2 availability — if B2 is the very thing that fails, S3 stops getting updates from that point. Independent plans cost a second source-read but give you true provider-redundancy.
- **Restore from S3 in an emergency**: same Restic command as B2, just point at the S3 URI with the admin AWS credentials. Standard-IA reads are instant, no thaw delay.
- **First-byte latency is slightly higher on Standard-IA** than Standard — adds maybe 50ms per object read. Imperceptible for backup-restore workflows.

## Adjacent concerns and unresolved questions

The strategy above covers what gets backed up, how, and to where. These items are *not* in the backup strategy proper but they determine whether the backup strategy actually works in practice. The first three are urgent; the rest can be scheduled.

### Critical (do these soon)

**1. Restic repository passwords stored outside the NAS** — ✓ *Resolved: stored in both Vaultwarden (self-hosted) and Bitwarden (cloud).* If `/mnt/fast/apps/backrest/config/backrest.json` is lost AND the passwords aren't elsewhere, every B2 backup becomes a permanently sealed brick — the data is encrypted with that password and no amount of B2-side recovery brings it back. Dual storage hedges against both NAS unavailability and any single password-vault provider going down.

**2. Backup-failure notifications** — Wire Backrest's notification hooks (Shoutrrr supports Discord, ntfy, generic webhooks, email). Without this, a failed `pg_dump` cron, a stuck Backrest run, or a B2 capability misconfiguration is invisible until your next restore attempt finds no recent snapshot. Silent failure is the single most common cause of "I had backups, but…" stories. At minimum: notify on `BACKUP_ERROR` and `CHECK_ERROR`; optionally also notify on `BACKUP_SUCCESS` weekly as a heartbeat.

**3. Quarterly restore rehearsal** — Pick one repo, restore to a scratch directory on your laptop, diff against the live source. An untested backup is not a backup. The first rehearsal will surface a problem with your assumptions (wrong path, wrong password store, B2 key missing a capability, retention dropped the snapshot you wanted) — better to find it now than during an actual incident. Calendar reminder for the first Sunday of every March, June, September, December.

### Operational

**4. Postgres ↔ filesystem consistency window**
`pg_dump` runs at 02:00; the `photos` plan runs on its own schedule. If a photo upload happens between them, the photos backup contains a file the DB snapshot doesn't know about; if a delete happens between them, the inverse. Restore-side reconciliation is messy but doable. Two mitigations:
- (a) accept eventual consistency and document the reconciliation steps in the restore runbook
- (b) chain the backups (pg_dump → photos backup) and pause Immich/Forgejo for the window

(a) is the standard homelab choice. Fine if written down.

**5. Restore time and egress**
A full ~189 GiB media-bucket restore from B2 at typical speeds is **6–12 hours** depending on connection. B2 includes free egress equal to 3× stored data per month, so one full restore costs nothing extra; multiple restores in one month incur $0.01/GiB after the free allowance. Critical-tier restore (1.3 GiB from either B2 or S3 Standard-IA) is under 5 minutes either way. Important to internalise *before* a real incident — bulk restore is not instant, and the dial-tone moment of "we're down, how long until we're back?" deserves a known answer.

**6. TrueNAS system config backup**
TrueNAS has its own *system config backup* (Settings → General → Manage Configuration → Download File). Contains user accounts, dataset layout, snapshot tasks, replication tasks, share definitions, NFS exports, app catalog state — none of which is in any data backup. Download after every meaningful config change and store in Vaultwarden. Tiny file, huge time-saver after a board failure.

**7. ZFS snapshot policy verification**
This strategy assumes ZFS snapshots are the local "human error" protection leg. Verify they're actually scheduled: TrueNAS → Data Protection → Periodic Snapshot Tasks.

Minimum coverage:
- `tank4/class1` — daily, 30-day retention
- `tank4/class2` — daily, 30-day retention

Without these, B2's daily-granularity is your *only* "I deleted that yesterday" recovery, which is worse than what ZFS can give you locally for free.

**8. Disaster-recovery runbook (separate document)**
The compose files in `~/.dotfiles/nas/apps/` are most of the recovery, but the deployment process itself isn't captured anywhere — where they're symlinked on the NAS, what user runs `docker compose up`, any systemd units involved, the order in which services come up. A one-page runbook in `~/.dotfiles/nas/RESTORE.md` along the lines of:

```
1. TrueNAS install on replacement hardware, import config from saved file
2. Import ZFS pools (or restore media from B2 if pools are lost too)
3. Authorize the admin B2 key (or S3 key, if B2 unavailable) from your laptop
4. Restic-restore the `secrets` tag from critical to recover secret files
5. Restic-restore the `postgres` tag from critical → run pg_restore against postgres
6. Restic-restore the `apps` tag from critical → app configs + LE certs in place
7. Clone dotfiles repo from Forgejo (or from local copy if Forgejo is down)
8. docker compose up -d on each compose.*.yaml in dependency order
9. Restic-restore media plans for photos/music/books/drive as needed
10. Verify: tailscale up, NPM proxy hosts, Immich, Forgejo, Vaultwarden
11. Re-issue Let's Encrypt certs if proxy/certs was lost (cert state should be in apps backup)
```

Critical tier can come from either B2 or S3 — pick whichever is reachable. Media is B2-only.

…closes the gap a stressed-out future-you will care about most.

### Threat-model gaps not closed by the two-key pattern

**9. NAS compromise = full read access to all backups**
The two-key pattern prevents an attacker on the NAS from *destroying* the offsite. It does NOT prevent them from downloading and decrypting every backup, because the Restic password is in `backrest.json` next to the B2 key. If your threat model includes "someone reads my photos", this isn't solved. Mitigation paths exist (HSM-stored keys, REST-server append-only fronting B2, separate encrypting filesystem) but they're well outside the homelab norm and add significant ops complexity.

**10. Backrest WebUI authentication hardening**
`backup.lan.zanbaldwin.com` has a single bcrypt user. UI compromise = control of all backup jobs (pause, modify retention, exfiltrate snapshots, trigger restore-as-attacker). Two improvements:
- Verify the NPM proxy host has an Access List restricting access to LAN + Tailscale CIDRs only, not exposing to the public internet
- Confirm the user password is long, unique, and stored in Vaultwarden — not reused from anywhere else

### Smaller things worth knowing

**11. B2 bucket names are globally unique** across all Backblaze customers. `zanbaldwin-nas-critical` is probably free; if it's taken, suffix with a random string. The name change has no operational impact beyond the URI in `backrest.json`.

**12. B2 region** — confirm during migration that the bucket is in `eu-central-003` (Frankfurt), not US-West. Affects egress latency, restore speed, and GDPR posture.

**13. Restic version skew** — Backrest bundles a specific Restic version. If you upgrade Backrest and the new version bumps the repository format, older Restic clients can't read until they also upgrade. Not an issue in steady state, but if you ever restore from a stale machine, upgrade its Restic before connecting to a recently-touched repo.

**14. Don't dismiss the `apps` plan as low-value** — Calibre tagging/metadata in `fast/apps/calibre/` and Navidrome's play counts/playlists/listen history in `fast/apps/navidrome/navidrome.db` are years of accumulated state. The underlying media survives without them, but losing the `apps` plan means losing all that contextual data even though "nothing is broken". Functional + sentimental value, not "skippable".

**15. This document needs to live somewhere durable** — currently in `/tmp/nas/BACKUP_STRATEGY.md` on your laptop. Move it into `~/.dotfiles/nas/` (so it's in the Forgejo repo → in `class2/code` → in the backup → in B2) before the next reboot, otherwise the entire planning conversation is one `rm /tmp` away from being gone.

## Smaller follow-up items (file these as TODOs)

1. **Local "copy 2" of the 3-2-1.** With B2 + S3, you have two offsite copies of critical (1.3 GiB) but only one offsite copy of media (189 GiB on B2). ZFS + RAID-Z on `tank4` is one local copy + redundancy, but still one disk subsystem in one chassis. A periodic `restic copy` of the media repo to a USB-attached repo or a second ZFS pool gives a true second medium for the bulk data. Out of scope per the brief; raise when ready.
2. **Stale `class2/backups/postgres.sql`** (339 MB) — delete via TrueNAS WebUI.
3. **`fast/home/zan`** is just the default shell skel (bashrc/profile/bash_logout). If you ever actually use it, include it in the `apps` plan or add a new `home` plan to the critical bucket.
