# HORSE | Host Only Resource / Script Executor

> [!IMPORTANT]
> HORSE relies on [this pull request](https://github.com/FiguraMC/Figura/pull/374) to not upload the host-only scripts.
> The [polyfill for addScript](./../addScriptPolyfill/README.md) works too!

HORSE follows the logic that host-only scripts don't need to be uploaded. By prefixing a file or folder with @, it will be marked as "host only." HORSE will then remove it from the NBT (via the pull request's addScript) and load it from the data folder (see config below)

```lua
HORSE.config = {
    folder = "folderName",       -- Name of the folder within the data folder to load from
    initScript = "init",         -- Script to require when HORSE is loaded (or bails)
    stage2 = "@preloadStage2",   -- Name of the second part of the HORSE; can be host-only
    scripts_per_tick = 25,       -- Amount of scripts to require from HORSE per tick
    debug = 0                    -- Minimum amount of time for entry to be logged. 0 to disable.
}
```

## Setting up
### Linux
You can make the data folder's copy of the avatar match the avatar folder's copy via mount --bind.
```sh
sudo mount --bind /path/to/figura/avatars/folderName /path/to/figura/data/folderName
```

### Windows
You can use a junction:
```cmd
cd path\to\figura
mklink /j .\avatars\folder .\data\folderName
``` 