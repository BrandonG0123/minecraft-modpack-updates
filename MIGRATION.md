# Moving this setup to another computer

Handoff for a session on the **new machine**. Everything needed is here; nothing
has to be copied by hand except the Prism instance itself.

Owner: Brandon (GitHub `BrandonG0123`). Minecraft **1.21.11**, Fabric **0.19.3**.

---

## What this repo is

A packwiz modpack published at
`https://brandong0123.github.io/minecraft-modpack-updates/`, built from a Prism
Launcher instance. It serves three packs plus two importable instance zips:

| Path | What it is |
|---|---|
| `pack.toml` | base - mods, worldgen configs, server list, light shaders, small resource packs |
| `plus/pack.toml` | base plus heavy shaders, all resource packs, personal client configs |
| `modsonly/pack.toml` | mods only, for friends keeping their own setup |
| `Tylers Mods.zip` / `Tylers Mods Plus.zip` | what friends import into Prism |
| `tools/dist/server-update.bat` | syncs a dedicated server with `-s server` |

**The Prism instance is the source of truth.** `publish.bat` reads it, rebuilds
all three packs, runs per-pack guards, rebuilds both zips and pushes. Editing
pack files by hand gets overwritten on the next sync.

## What is machine-specific

Exactly one thing. Every tool defaults to:

    $Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)"

`$env:APPDATA` resolves per-user, so this works unchanged on any Windows machine
**provided the instance has the same name**. If the new machine names it
differently, either rename it there or update the default in these five files:

    tools/sync-from-instance.ps1
    tools/import-from-instance.ps1
    tools/import-assets.ps1
    tools/diff-instance.ps1
    tools/fix-sides.ps1

Nothing else is tied to a machine. The GitHub Pages URL is baked into
`make-friend-zip.ps1` and the server scripts, which is correct - it is where the
pack is published, not where it is built.

## Migration steps

1. **Clone**

       git clone https://github.com/BrandonG0123/minecraft-modpack-updates
       cd minecraft-modpack-updates

2. **Fetch packwiz** - the binary is gitignored (12MB, expires from CI)

       tools\update-packwiz.bat

3. **GitHub auth**, needed to publish. Either install GitHub CLI and run
   `gh auth login`, or let Git Credential Manager prompt on first push.

4. **The Prism instance.** This is the real migration. Either:
   - copy `%APPDATA%\PrismLauncher\instances\Mods(BG and Friends)` across, or
   - import `Tylers Mods Plus.zip` on the new machine and launch it once, which
     pulls every mod and config from the published pack

   The second is cleaner and gives an instance already matching the pack.

5. **Verify** - this should report no differences:

       tools\check-changes.bat

6. **Optional**: desktop shortcuts to `tools\publish.bat` and the repo folder.

## Do not publish from two machines without pulling first

Both machines pushing to `main` will conflict. Always `git pull` before
`publish.bat` on whichever machine you are using, or retire the old one once the
new machine is verified working.

## What does not transfer

- `_backups/` is gitignored and stays on the old machine. It holds the original
  copies of every Prism file that was modified there.
- `tools/bin/` (packwiz.exe, gh.exe) - gitignored, re-fetched in step 2.
- Nothing else. The pack, all three variants, every script and both zips are in
  the repo.

## Ground rules

- Mods change in Prism, never in the pack folder. Then `publish.bat`.
- `remove-mod.bat` stops shipping a mod while keeping it locally - it records
  the exclusion in `tools/exclude-mods.txt`, because deleting metadata alone
  would be undone by the next sync.
- Mod sides are derived from each jar's `fabric.mod.json`, then a transitive
  pass marks anything hard-depending on a client-only mod as client-only too,
  then `tools/side-overrides.txt` applies manual decisions. Do not hand-edit
  `side` in a `.pw.toml`; it is regenerated every sync.
- Guards run before every push and block it if private data reaches an index -
  waypoints, worlds, screenshots, account data, caches. `modsonly` additionally
  rejects anything outside `mods/`.
