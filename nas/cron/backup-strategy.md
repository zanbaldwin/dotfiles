# NAS Backup Strategy

Planning document. No changes have been made to the NAS or to `backrest.json`.

## Goals (confirmed)

1. **Hardware redundancy / offsite (3-2-1):** Backblaze B2 covers the offsite leg. ZFS on `tank4` + TrueNAS snapshots cover local redundancy/human-error. Only the B2 target is in scope right now.
2. **Protection against credential theft / ransomware on the NAS:** The B2 credentials sitting on the NAS must not be able to *delete* what's already backed up.
3. **Protection against human error:** ZFS snapshots are the first line; B2 retention is the second.
4. **Moderate retention** at €6/TB/month.

## Diagnosis: what the current config actually covers

The Backrest config currently has two plans:

| Plan | Source | Backed up? |
|---|---|---|
| `B2-Class1` | `/mnt/tank4/class1` | Yes |
| `B2-Postgres` | `/mnt/tank4/backups/postgres` | Yes |

Compared to what's on the NAS, the following is **not currently backed up**:

| Path | Size | Notes |
|---|---|---|
| `class2/photos` | 69 GB | Immich originals. Critical. |
| `class2/music` | 103 GB | Critical. |
| `class2/code` | 162 MB | Forgejo bare repos. |
| `class2/documents` | 443 MB | |
| `class2/drive` | 4.9 GB | General file dump. |
| `class2/backups` | 339 MB | Stale `postgres.sql` leftover — recommend delete. |
| `fast/apps/*` | ~32 MB | Proxy NPM config, Navidrome DB, Memos *files only* (DB in Postgres), Calibre-Web, Tailscale state. |
| `class3/forgejo` | 375 K | Per your decision: **skipped**. See "Class3 risk note" below. |
| `class3/immich` | 24 G | Regenerable (thumbs 7.5G, encoded-video 16G, upload staging 646M). Skipped. |

Together this is ~178 GB of currently-unprotected data. At €6/TB that's about **€1.07/month** of B2 storage, plus a small overhead for retention.

## Recommended structure

Per your answers: **two-key Restic pattern**, **two buckets (critical + bulk)**, **skip all of class3**, **tuned per-repo retention**.

### Buckets

```
zanbaldwin-nas-critical   ← small, change-heavy, long retention
zanbaldwin-nas-bulk       ← large, change-light, shorter retention
```

### Restic repos (one per logical concern, under the matching bucket)

| Repo URI | Sources | Bucket |
|---|---|---|
| `b2:zanbaldwin-nas-critical:/class1` | `/mnt/tank4/class1` | critical |
| `b2:zanbaldwin-nas-critical:/postgres` | `/mnt/tank4/backups/postgres` | critical |
| `b2:zanbaldwin-nas-critical:/code` | `/mnt/tank4/class2/code` | critical |
| `b2:zanbaldwin-nas-critical:/documents` | `/mnt/tank4/class2/documents` | critical |
| `b2:zanbaldwin-nas-critical:/apps` | `/mnt/fast/apps` (excluding postgres data dir + paperless logs/index — see excludes) | critical |
| `b2:zanbaldwin-nas-bulk:/photos` | `/mnt/tank4/class2/photos` | bulk |
| `b2:zanbaldwin-nas-bulk:/music` | `/mnt/tank4/class2/music` | bulk |
| `b2:zanbaldwin-nas-bulk:/drive` | `/mnt/tank4/class2/drive` | bulk |

Rationale for splitting per-concern (rather than one giant `class2` repo):
- Each repo gets its own retention policy.
- Each repo is independently restorable. You don't have to pull a 200 GB index just to recover a single PG dump.
- Each repo can be checked/pruned independently — `restic check --read-data` on the music repo is expensive; on `postgres` it's free.

### Why `code` lives in `critical` even though it's in `class2`

The repos are 162 MB and the *most* mutationally interesting thing in the system. Putting them in `critical` means longer retention (deeper history) without meaningful cost. Forgejo's git-gc can repack and slightly inflate Restic chunks, but at this size it's irrelevant. If `code` ever grows past a few GB and the prune overhead becomes visible, periodic `git bundle` snapshots can replace direct backup — but not today.

### Retention shapes (per-repo)

Group A — **Critical / small** (`class1`, `postgres`, `code`, `documents`, `apps`):
```
daily   = 14
weekly  = 8
monthly = 12
yearly  = 2
```

Group B — **Bulk / mostly-immutable** (`photos`, `music`):
```
daily   = 7
weekly  = 4
monthly = 3
yearly  = 1
```
(Music almost never changes, so monthlies/yearlies are nearly free.)

Group C — **Bulk / mutable** (`drive`):
```
daily   = 7
weekly  = 4
monthly = 6
yearly  = 1
```

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

## Postgres backup hardening (optional, recommended)

Current: a single `pg_dumpall` → `databases.sql` (617 MB). Two refinements worth considering:

1. **Per-database dumps in custom format** for selective restore:
   ```bash
   for db in main forgejo immich memos; do
     pg_dump -Fc -U main -d "$db" -f "/backup/${db}.dump"
   done
   pg_dumpall -U main --globals-only -f /backup/globals.sql
   ```
   `pg_restore -d immich immich.dump` is much faster than picking through a 617 MB monolithic SQL file. `globals.sql` keeps the role definitions for a clean rebuild.

2. **Move the dump location** from `/mnt/tank4/backups/` (an un-classed top-level dir) to `/mnt/tank4/class1/backups/postgres/` for naming consistency. The class1 plan would then cover it automatically, and you can retire the separate `B2-Postgres` plan. (Skip if you'd rather keep the postgres plan logically separate — it's a wash.)

The stale `/mnt/tank4/class2/backups/postgres.sql` (339 MB) should be deleted via the TrueNAS WebUI.

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

Using B2 list price ($0.006/GiB-month) past the 10 GB free tier:

| Repo | Approx size | Notes |
|---|---:|---|
| `class1` | 13 GiB | books + secrets, ~write-once |
| `postgres` | 0.6 GiB | grows slowly with DB |
| `code` | 0.2 GiB | git churn small at this size |
| `documents` | 0.5 GiB | low churn |
| `apps` | 0.03 GiB | tiny, sees daily app config writes |
| `photos` | 69 GiB | grows as Immich grows |
| `music` | 103 GiB | effectively write-once |
| `drive` | 4.9 GiB | moderate churn |
| **Total stored** | **~191 GiB** | |
| - Free tier | -10 GiB | |
| **Billable storage** | **~181 GiB** | **$1.09/month** |

Plus retention overhead (typically +15–25% on a Restic repo with active churn, much less on the immutable repos): realistic ongoing total **$1.25–$1.40/month**, dominated entirely by `music` + `photos`.

Note: if you enable Object Lock with a 14-day default retention, prune'd data will keep being billed until its lock expires. For your retention shapes that adds maybe 1–2 GiB of "ghost storage" at any given time — about $0.01/month. Not material.

### Cost over the first year

Initial seed transfer is free (uploads to B2 don't cost anything). Once seeded, expect:

- Month 1–2: ~$1.30/month as the index settles
- Steady state: ~$1.40/month, drifting up by maybe $0.05/month per year as photos/music grow
- A version-stomping incident (if it happens): temporary doubling for the 30-day version retention window. Even in the worst case this caps at ~$2.50/month for one month.

The version retention rule (Option A in the protection section) is essentially free in normal operation — old versions only accumulate during the brief moment between an old pack being superseded and the lifecycle rule expiring it.

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

**Bucket 2: `zanbaldwin-nas-bulk`** — same settings.

#### Migration note

You have an existing `zanbaldwin-nas-backup` with two Restic repos (`/class1`, `/database/postgres`) and 12.6 GiB of data. Two paths:

- **Path A (recommended): repurpose the existing bucket.** Rename it mentally to "critical". Add the new repos (`/code`, `/documents`, `/apps`) alongside the existing two. Create only one new bucket (`zanbaldwin-nas-bulk`). Trade-off: cannot enable Object Lock on the existing bucket retroactively if it was created without versioning, so you'd be on Option A (lifecycle-based version retention) for the critical bucket. Versioning has been on by default for B2 buckets for years, so check the bucket's setting before assuming.
- **Path B (clean slate): create both buckets fresh.** `restic init` two new repos per bucket, then run a fresh backup. Existing `class1` + `postgres` data re-uploads (~13 GB, free upload, no egress cost). After verifying the new backups work, delete the old bucket. Cleaner naming, but throws away historical snapshot history in the existing repos.

For Path A, the existing repo URIs in `backrest.json` stay the same (`b2:zanbaldwin-nas-backup:/class1`, etc.); only the *application key* rotates.

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
  --bucket zanbaldwin-nas-bulk \
  --capabilities listBuckets,listFiles,readFiles,writeFiles,readBucketEncryption \
  backrest-nas-bulk
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

If both behave as described, the key is correctly scoped. Run the same probe against `zanbaldwin-nas-bulk`. Then *also* upload a second version of the same file name and confirm via the admin key that both versions exist — this verifies versioning is on and the lifecycle rule is in scope:

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

In the Backrest web UI (`backup.lan.zanbaldwin.com`), for each repo:

- Edit the repo's `env` to point at the new bucket-scoped backup key (`B2_ACCOUNT_ID` and `B2_ACCOUNT_KEY`).
- For new repos (`code`, `documents`, `apps`, `photos`, `music`, `drive`): click **Add Repo**, set the URI to `b2:zanbaldwin-nas-critical:/<repo-name>` (or `nas-bulk` as appropriate), paste the key, and let Backrest run `restic init`.
- For each repo, **remove or disable** the `prunePolicy` (you'll prune from your laptop with the admin key). `checkPolicy` can stay — it only reads.
- Add the matching `Plan` (sources + retention shape per the table earlier in this doc).

You can leave the old repo definitions alone until the new ones have a successful backup, then delete the old `B2-Postgres` plan and the `B2-Class1` plan if you took Path B (clean slate), or leave them in place if you took Path A (existing bucket reused).

### Step 7 — Rotate / revoke the old master-keyed access

Once everything is migrated and verified:

In the B2 console: **App Keys → [old master/full key used in current `backrest.json`] → Delete**.

This removes the old single-credential blast-radius from the system. The master account key (the one tied to your login) stays — you'll need it occasionally to mint new keys — but it should never live in any config file.

### Step 8 — Monthly prune ceremony (from your laptop)

Add a calendar reminder for the first Sunday of each month:

```bash
# Authorize with admin key
b2 account authorize <admin keyID> <admin applicationKey>
export B2_ACCOUNT_ID=<admin keyID>
export B2_ACCOUNT_KEY=<admin applicationKey>

# Per-repo, with the retention shape from the strategy:
for repo in class1 postgres code documents apps; do
  restic -r "b2:zanbaldwin-nas-critical:/$repo" forget --prune \
    --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 2
done

for repo in drive; do
  restic -r "b2:zanbaldwin-nas-bulk:/$repo" forget --prune \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
done

for repo in photos music; do
  restic -r "b2:zanbaldwin-nas-bulk:/$repo" forget --prune \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --keep-yearly 1
done
```

Restic's repo password (separate from the B2 key) lives in `backrest.json` on the NAS — copy it into Vaultwarden so the laptop can prune. The Restic password is what actually encrypts the backup data; the B2 key is only access control on the storage side.

## Open follow-ups (for a separate conversation)

These aren't required for the strategy but are worth flagging:

1. **Local "copy 2" of the 3-2-1.** ZFS snapshots + RAID-Z on `tank4` is one copy + redundancy, but it's still one disk subsystem in one chassis. A periodic `restic copy` to a USB-attached repo or a second ZFS pool gives a true second medium. Out of scope per your prompt; raise when ready.
2. **Per-DB pg_dump cron rework** (described above) — small, separable change.
3. **Stale postgres.sql cleanup** in `class2/backups/` — delete via WebUI.
4. **Move postgres dump path** from `/mnt/tank4/backups/` to `class1/backups/postgres/` for consistency — optional.
5. **`fast/home/zan`** is just the default skel (bashrc/profile/bash_logout). If you ever actually use it, it should be included in the `apps` repo or a new `home` repo.
