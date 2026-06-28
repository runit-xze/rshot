import os, re, sys

# Load the TODO list to get modules that still need documentation (Phase 3)
TODO_PATH = "GEMINI_FIX_TODO.md"
modules = []
with open(TODO_PATH, "r") as f:
    for line in f:
        m = re.match(r"- \[ \] (.+)", line.strip())
        if m:
            modules.append(m.group(1).strip())

# Helper to extract POD description (simple heuristic: everything between first =head and =cut)
def extract_pod(content):
    pod = []
    in_pod = False
    for line in content.splitlines():
        if line.startswith('=head'):
            in_pod = True
        if in_pod:
            pod.append(line)
        if line.strip() == '=cut':
            break
    return "\n".join(pod).strip()

# Helper to list subroutine names (excluding private/internal helpers)
def list_subs(content):
    subs = []
    for line in content.splitlines():
        line = line.strip()
        if line.startswith('sub ') and not line.startswith('sub _'):
            # capture name until first space or { or (
            name = re.split(r"[\s{(]", line[4:])[0]
            subs.append(name)
    return subs

for mod in modules:
    # Convert module name to file path
    rel_path = mod.replace('::', '/') + '.pm'
    pm_path = os.path.join('share/shutter/perl/Shutter', rel_path)
    if not os.path.isfile(pm_path):
        # skip if source missing
        continue
    with open(pm_path, 'r', errors='ignore') as f:
        pm_content = f.read()
    # Extract POD (if any)
    pod = extract_pod(pm_content)
    # List methods
    methods = list_subs(pm_content)
    # Build markdown content
    md_path = os.path.join('GEMINI', rel_path.replace('.pm', '.md'))
    os.makedirs(os.path.dirname(md_path), exist_ok=True)
    with open(md_path, 'w') as md:
        md.write(f"# {mod}\n\n")
        md.write(f"**File Path:** `{pm_path}`\n\n")
        md.write("## Description\n")
        if pod:
            md.write(pod + "\n\n")
        else:
            md.write(f"Documentation for `{mod}`. This module handles functionality related to {mod.split('::')[-1]}.\n\n")
        if methods:
            md.write("## Methods\n")
            for s in sorted(set(methods)):
                md.write(f"- `{s}`\n")
            md.write("\n")
        # Simple dependencies extraction
        deps = []
        for line in pm_content.splitlines():
            line = line.strip()
            if line.startswith('use ') and not any(line.startswith(p) for p in ('use strict', 'use warnings', 'use v5', 'use feature')):
                dep = line.split()[1].replace(';', '')
                deps.append(dep)
        if deps:
            md.write("## Dependencies\n")
            for d in sorted(set(deps)):
                md.write(f"- `{d}`\n")
            md.write("\n")

print(f"Generated documentation for {len(modules)} modules.")
