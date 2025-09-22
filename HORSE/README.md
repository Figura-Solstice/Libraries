# HORSE | Host Only Resource / Script Executor

> [!IMPORTANT]
> HORSE relies on [this pull request](https://github.com/FiguraMC/Figura/pull/374) to not upload the host-only scripts.
> But the [polyfill for addScript](./../addScriptPolyfill/README.md) works too!

HORSE follows the logic that host-only scripts don't need to be uploaded. By prefixing a file or folder with `@`, it will be marked as "host only." HORSE will then remove it from the NBT (via the pull request's addScript) and load it from the data folder (see config below). It also reads and adds any textures prefixed with an `@`. this is especially useful for if you have something external that makes figura ignore paths that have an `@` at the start of a folder/file name. (Keep an eye out for that :3) 

## Files
| Required | Filename | Purpose |
| --------  | -------- | ------- |
| No | `init.lua` | Example "normal" script |
| Yes | `preload.lua` | Stage 1, handles loading stage 2 from data directory. Intentionally minimal. |
| Yes| `@preloadStage2.lua` | Stage 2, the bulk of HORSE, which handles loading the rest of the host only scripts. |

## Config
```lua
-- this is in preload.lua
HORSE.config = {
    folder = "folderName",       -- Name of the folder within the data folder to load from
    initScript = "init",         -- Script to require when HORSE is loaded (or bails)
    stage2 = "@preloadStage2",   -- Name of the second part of the HORSE; can be host-only
    scripts_per_tick = 25,       -- Amount of scripts to require from HORSE per tick
    debug = 0                    -- Minimum amount of time for entry to be logged. 0 to disable.
}
```

## Setting up "symlinks"
HORSE was designed to read your avatar from the data folder (though theoretically it supports just having a folder of host only scripts), so if you don't want to repeatedly copy of the files, I recommend linking the two directories.
### Linux
You can make the data folder's copy of the avatar match the avatar folder's copy via mount --bind.
```sh
sudo mount --bind /path/to/figura/avatars/folderName /path/to/figura/data/folderName
```

### Windows
You can use a junction:
```cmd
cd path\to\figura
mklink /j .\data\folder .\avatars\folderName
``` 
*(if a windows user could triple check if that's right, i'd appreciate it)*

## Avatar structure
HORSE is designed to run before everything else in your avatar, so the recommended avatar.json looks something like this:
```json
{
    "name": "Cool Avatar",
    "description": "My cool avatar",
    "autoScripts": [
        "path.to.HORSE"
    ]
}
```

You would then define an "init script" that HORSE runs via the config (see [#Config](#config))

## Dependencies
- Hard dependency: [SolsticeCallbacks](../SolsticeCallbacks/README.md) (TODO: extract SC's logic into HORSE)
- Soft dependency: [addScriptPolyfill](../addScriptPolyfill/README.md) (Only if you're on a version below Figura v0.1.6)
