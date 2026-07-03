# File Weaver Community Library

The official library of presets and rules for [File Weaver](https://www.sprocketconsulting.co.uk/file-weaver), the macOS file renaming app.

## Using this library

**In the app (File Weaver 1.4+):** open Settings → Library. This library is pre-listed; click **Refresh** to load its catalogue, then **Download** any entry you want. Nothing is fetched until you ask.

**Manually:** browse the `presets/` and `rules/` folders on GitHub, download any `.fwl` file, and double-click it — File Weaver validates it and asks before adding anything.

## Contents

- `presets/` — complete rule sets (`.fwl` files with `"kind": "preset"`)
- `rules/` — saved settings for a single rule (`"kind": "rule"`)
- `fwl-library.json` — the manifest that identifies this repository as a File Weaver library and indexes every entry

## Contributing / making your own library

Any public GitHub repository with a valid `fwl-library.json` at its root is a File Weaver library. See *Configuring a File Weaver Library repository.md* and *FWL File Format.md* in the File Weaver documentation for the formats. Run `./validate.sh` before committing to check the manifest and every `.fwl` file.

A `.fwl` file contains only declarative rule settings. Script rules use File Weaver's built-in, sandboxed scripting language — no external code is downloaded or executed.
