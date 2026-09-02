# Tylers Mods — auto-updating modpack

Minecraft **1.21.11** · Fabric **0.19.3** · 100 mods

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

The first launch downloads ~100 mods, so it takes a few minutes and shows a
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
- Xaero's minimap waypoints, Litematica schematics, JEI/inventory layouts
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

### Other tools

| Script | What it does |
|---|---|
| `publish.bat` | **The main one.** Sync from your instance → commit → push. |
| `check-changes.bat` | Read-only. Shows what differs between your instance and the published pack. |
| `update-all.bat` | Ask Modrinth for newer versions of every mod (updates the pack, not your instance). |
| `add-mod.bat` | Add a mod to the pack directly by Modrinth slug/URL. |
| `remove-mod.bat` | Remove a mod from the pack directly. |
| `publish-pack-only.bat` | Push the pack without re-reading your instance. Use after the three above. |
| `update-packwiz.bat` | Re-download the current packwiz build. |
| `gh-login.bat` | One-time GitHub sign-in. |

### Changing the managed config list

Edit `modpack-tools\managed-configs.txt` — one path per line, relative to the
instance's `minecraft\` folder. Add a line to start managing a config; delete a
line **and** delete the matching file from `config/` in this repo to stop.
Then run `publish.bat`.

### Changing Minecraft or Fabric version

Edit `[versions]` in `pack.toml`, then `publish.bat`. Friends' Prism instances
update their Minecraft and Fabric Loader versions automatically on next launch.
