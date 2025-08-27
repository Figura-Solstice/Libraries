# addScriptPolyfill
Simple drop-in-and-require polyfill that implements enough of `addScript` to make HORSE work 1:1 with<sup>*</sup> 0.1.6. If `addScript` already exists (for instance, if defined from lua, an addon, or by just using 0.1.6 or above), the polyfill will simply do nothing.

This script patches or adds the following functions:
- require(mod)
- listFiles(dir, recursive)
- addScript(scriptName, contents, side<sup>**</sup>)


<sub>\* (Theoretically)</sub>

<sub>\*\* (side argument is ignored, as it is impossible to write the scripts to NBT without an addon. It functions as though the value passed was "RUNTIME".)</sub>


## Files
| Required | Filename | Purpose |
| -------- | -------- | ------- |
| Yes      | `addScriptPolyfill.lua` | Contains the backported features.