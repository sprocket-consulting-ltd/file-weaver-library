#!/bin/bash
# Validates fwl-library.json and every .fwl file it references.
# Works with macOS bash 3.2. Requires python3.

set -e
cd "$(dirname "$0")"

python3 - <<'PYEOF'
import json, os, sys

errors = []

RULE_TYPES = {
    "Find & Replace", "Add Prefix / Suffix", "Sequential Number", "Change Case",
    "Regex Replace", "Insert Text", "Trim Spaces", "Strip Text", "Map Extension",
    "Script", "Set Variable", "Set Name",
}

def err(msg):
    errors.append(msg)

# ---- manifest ----
try:
    with open("fwl-library.json", encoding="utf-8") as f:
        manifest = json.load(f)
except Exception as e:
    print(f"FATAL: fwl-library.json unreadable: {e}")
    sys.exit(1)

if manifest.get("libraryFormatVersion") != 1:
    err("manifest: libraryFormatVersion must be 1")
if not manifest.get("name"):
    err("manifest: name is required")
entries = manifest.get("entries")
if not isinstance(entries, list):
    err("manifest: entries must be an array")
    entries = []

listed_paths = set()
for i, e in enumerate(entries):
    where = f"manifest entry {i} ({e.get('name', '?')})"
    path = e.get("path", "")
    listed_paths.add(path)
    if not path.endswith(".fwl") or path.startswith("/") or ".." in path:
        err(f"{where}: bad path {path!r}")
        continue
    if not os.path.isfile(path):
        err(f"{where}: file not found: {path}")
        continue
    if e.get("kind") not in ("preset", "rule"):
        err(f"{where}: kind must be 'preset' or 'rule'")
    if not e.get("name"):
        err(f"{where}: name is required")
    for rt in e.get("ruleTypes", []):
        if rt not in RULE_TYPES:
            err(f"{where}: unknown ruleType {rt!r}")

    # ---- the .fwl file itself ----
    try:
        with open(path, encoding="utf-8") as f:
            fwl = json.load(f)
    except Exception as ex:
        err(f"{path}: invalid JSON: {ex}")
        continue
    if os.path.getsize(path) > 1_000_000:
        err(f"{path}: exceeds 1 MB limit")
    if fwl.get("fwlVersion") != 1:
        err(f"{path}: fwlVersion must be 1")
    kind = fwl.get("kind")
    if kind != e.get("kind"):
        err(f"{path}: kind {kind!r} != manifest kind {e.get('kind')!r}")
    if fwl.get("name") != e.get("name"):
        err(f"{path}: name {fwl.get('name')!r} != manifest name {e.get('name')!r}")
    if kind == "preset":
        rules = fwl.get("rules")
        if not isinstance(rules, list) or not rules:
            err(f"{path}: 'rules' must be a non-empty array")
            rules = []
    elif kind == "rule":
        rule = fwl.get("rule")
        if not isinstance(rule, dict):
            err(f"{path}: 'rule' must be an object")
            rules = []
        else:
            rules = [rule]
            if fwl.get("ruleType") != rule.get("type"):
                err(f"{path}: ruleType != rule.type")
    else:
        err(f"{path}: kind must be 'preset' or 'rule'")
        rules = []
    for j, r in enumerate(rules):
        if r.get("type") not in RULE_TYPES:
            err(f"{path}: rule {j}: unknown type {r.get('type')!r}")

# ---- orphan check ----
for folder in ("presets", "rules"):
    if os.path.isdir(folder):
        for fn in os.listdir(folder):
            p = f"{folder}/{fn}"
            if fn.endswith(".fwl") and p not in listed_paths:
                err(f"{p}: not listed in fwl-library.json")

if errors:
    print(f"FAILED — {len(errors)} problem(s):")
    for m in errors:
        print(f"  - {m}")
    sys.exit(1)
print(f"OK — manifest and {len(entries)} entries validated.")
PYEOF
