# Tylers Mods — auto-updating modpack

Minecraft **1.21.11** · Fabric **0.19.3** · 110 mods

This repo *is* the modpack. It holds packwiz metadata — small `.toml` files that
point at Modrinth downloads — not the mod jars themselves. Players' launchers
read it and fetch the jars directly from Modrinth.

Pack URL: `https://brandong0123.github.io/minecraft-modpack-updates/pack.toml`

---

## For players (first time)

1. Install [Prism Launcher](https://prismlauncher.org/download/) and sign in with your Minecraft account.
2. Get `Tylers Mods.zip` from Tyler.
3. In Prism: **Add Instance → Import from zip →** pick that file → **OK**.
4. Click **Launch**.

The first launch downloads 110 mods, so it takes a few minutes and shows a
progress window. Every launch after that checks for changes in seconds.

## For players (updating)

Nothing. Click **Launch**. Mods sync automatically before the game starts.

### What is yours and stays yours

The updater only ever touches files it installed. These are never read,
overwritten, or deleted:

- `shaderpacks/` — your shaders, including which one is selected
- `resourcepacks/` — your resource packs and their load order
- `saves/` — your worlds
- `screenshots/`
- `logs/`, `crash-reports/`
- `options.txt` — video settings, FOV, **keybinds**
- `optionsof.txt`, `optionsshaders.txt`
- `xaero/` and `XaeroWaypoints*/` — your minimap/world-map waypoints, per-server
  map data and server list. These live in their OWN top-level folders, not just
  `config/`, and none of it is ever read or shipped.
- `config/xaero/`, `xaerohud.txt` — minimap appearance and keybinds
- Litematica schematics, JEI/inventory layouts, MaLiLib keybinds
- Any mod you add yourself that isn't part of the pack

### What is centrally managed

- Everything in `mods/`
- 27 files under `config/` that define worldgen and gameplay rules
  (Terralith, Tectonic, TerraBlender, Biomes O' Plenty, Biomes We've Gone,
  CTOV, Lithostitched, Farmer's Delight, Waystones, Traveler's Backpack,
  VeinMiner, Enchanting Infuser, Falling Tree, Right Click Harvest, Enderite,
  Trade Cycling, Image2Map)

Those configs are reset to the pack's version on launch — they have to match or
worlds generate differently. Every other config file is yours to change freely:
Sodium, Iris, Distant Horizons, Xaero's, Litematica, MaLiLib, JEI, Zoomify,
ModMenu, sound and visual mods are all personal.

---

## For Tyler (publishing changes)

Your Prism instance `Mods(BG and Friends)` is the source of truth. Add, remove,
or update mods there however you normally do — Prism's mod browser, dragging
jars in, whatever.

Then run **one** thing:

    modpack-tools\publish.bat

It re-reads your instance, rebuilds the metadata, and pushes. Friends get it on
their next launch.

### The tools

| Script | What it does |
|---|---|
| `publish.bat` | **The main one.** Mirrors your instance into the pack, then pushes. |
| `check-changes.bat` | Read-only. What differs between your instance and the published pack. |
| `check-updates.bat` | Read-only. Which shipped mods have a newer version on Modrinth. |
| `remove-mod.bat` | Stop shipping a mod. The jar stays in your instance. |
| `add-mod.bat` | Reminder of the add flow (add it in Prism, then publish). |
| `update-packwiz.bat` | Re-download the current packwiz build. |
| `gh-login.bat` | One-time GitHub sign-in. |

**Your Prism instance is the source of truth.** `publish.bat` copies *from* it, so
editing the pack folder by hand gets overwritten on the next publish. The one
exception is `exclude-mods.txt`, which is how you keep a mod locally without
shipping it.

### Changing the managed config list

Edit `modpack-tools\managed-configs.txt` — one path per line, relative to the
instance's `minecraft\` folder. Add a line to start managing a config; delete a
line **and** delete the matching file from `config/` in this repo to stop.
Then run `publish.bat`.

### Changing Minecraft or Fabric version

Edit `[versions]` in `pack.toml`, then `publish.bat`. Friends' Prism instances
update their Minecraft and Fabric Loader versions automatically on next launch.

### About the 10 formerly-disabled mods

Ten mods were switched off (`.disabled`) in Tyler's instance and are now shipped
**enabled** to everyone: Config API, Yamato Gun, Breaking Bedrock, Collective,
Healing Campfire, MCPitanLib, PortalGunMod, Xaero's PlayerPosition, XaeroShare,
Yori3o's Grappling Hooks.

To drop any of them later: `modpack-tools\remove-mod.bat`, pick the name, then
`publish-pack-only.bat`. One mod is one small file — removal is cheap and safe.

### Publish safety net

`publish.bat` runs `guard-personal-data.ps1` before every push. It scans the pack
index and **refuses to publish** if anything player-personal has crept in —
waypoints, saves, screenshots, shaderpacks, resourcepacks, `options.txt`, server
lists, keybind configs. A blocked publish pushes nothing and tells you which file
tripped it.
