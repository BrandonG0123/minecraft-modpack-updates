# Server briefing

Read this first. It is the handoff for work on the **dedicated server machine**,
written from the client machine where the modpack itself was built. A session on
the server box starts with no memory of that work, so everything needed is here.

Owner: Brandon (GitHub `BrandonG0123`). Minecraft **1.21.11**, Fabric **0.19.3**.

---

## What already exists

A packwiz modpack published at
`https://brandong0123.github.io/minecraft-modpack-updates/`
built from the Prism instance `Mods(BG and Friends)` on the client PC.

Four things are served from it:

| Path | What it is |
|---|---|
| `pack.toml` | base pack - 107 mods, 29 worldgen configs, server list, 5 shaders, 8 resource packs |
| `plus/pack.toml` | same mods + 14 shaders, 26 resource packs, personal client configs |
| `modsonly/pack.toml` | 107 mods and nothing else |
| `tools/dist/server-update.bat` | the server-side updater described below |

Mod `side` values are taken from each jar's own `fabric.mod.json` `environment`
field, not Modrinth's tags (those were wrong on several worldgen mods). Of the
107 mods: **74 declare `*`** and are server-safe, **33 declare `client`**, none
are server-only.

That means the server uses the *same* base pack with `-s server` and
automatically gets only the 74 it can run - no Sodium, Iris, Litematica,
Xaero's Minimap client bits, ModMenu or Essential.

Verified by real installs: `-s server` -> 74 mods + 29 configs + 0 shaders +
0 resource packs. `-s client` -> 107 mods + 29 configs + 5 shaders + 8 packs.

---

## Task 1 - the server will not start

It was killed while shutting down (`start.bat` closed mid-stop). In order of
likelihood:

1. **Old Java process still alive**, holding port 25565 and the world session
   lock. `tasklist | findstr java` then `taskkill /F /IM java.exe /IM javaw.exe`.
   This is the usual cause.
2. **Port still bound** - `netstat -ano | findstr :25565`, kill the owning PID.
3. **Stale `world/session.lock`** - safe to delete, it is recreated.
4. **`world/level.dat` truncated mid-write** - restore from `world/level.dat_old`
   (back up the `world` folder first).

`start.bat` probably closes instantly and hides the error. Run it from an
already-open `cmd`, or read the tail of `logs/latest.log`.

**Never** delete the `world` folder or any `region/*.mca` files.

## Task 2 - wire up auto-updating

Put `server-update.bat` next to `server.properties`:

    curl -o server-update.bat https://brandong0123.github.io/minecraft-modpack-updates/tools/dist/server-update.bat

Then add two lines at the top of the existing `start.bat`, above the java line:

    call "%~dp0server-update.bat"
    if errorlevel 1 exit /b 1

It downloads `packwiz-installer-bootstrap.jar` on first run, syncs with
`-s server`, and aborts the start if the sync fails rather than booting a
mismatched server.

## Task 3 - tidy the server folder

Brandon says it is messy. Nothing here has seen it. Inspect before deleting.

Safe to remove: `crash-reports/`, old `logs/*.log.gz`, stray `*.jar.bak`,
duplicate mod jars, leftover installer jars.

Never remove: `world/`, `world_nether/`, `world_the_end/`, `server.properties`,
`ops.json`, `whitelist.json`, `banned-*.json`, `eula.txt`.

**The `mods` folder becomes managed by the updater** - once Task 2 is done,
packwiz owns it. Any mod not in the pack should be removed, or it will sit
alongside the managed copy and can crash Fabric with duplicate mods.

Known drift: a folder of server mods on the client PC (`Desktop\srve`) held
much older builds - Terralith 2.5.14 vs 2.6.1, Fabric API 0.141.1 vs 0.141.6,
BOP 21.11.0.11 vs .32. If the server is running those, it is well out of date
and one updater run fixes it.

## Ground rules

- The Prism instance on the *client* PC is the source of truth for mods.
  Never edit pack files on the server; changes flow client -> repo -> server.
- Back up `world/` before anything destructive.
- If a mod must be dropped, do it on the client PC via `remove-mod.bat`, not by
  deleting jars on the server - the updater would just put it back.
