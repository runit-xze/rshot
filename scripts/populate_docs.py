import os
import re

def parse_pm(pm_path):
    if not os.path.exists(pm_path):
        return None, [], []

    package = None
    deps = []
    methods = []
    
    with open(pm_path, 'r', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line.startswith('package '):
                package = line.replace('package ', '').replace(';', '')
            elif line.startswith('use ') and not line.startswith('use strict') and not line.startswith('use warnings'):
                deps.append(line.replace('use ', '').replace(';', '').split()[0])
            elif line.startswith('sub ') and not '{' in line.split('sub ')[1] and not line.endswith(';'):
                # Handle `sub foo {` or `sub foo ($self) {`
                m = re.match(r'^sub\s+([A-Za-z0-9_]+)', line)
                if m:
                    methods.append(m.group(1))

    return package, list(set(deps)), methods

for root, _, files in os.walk("GEMINI"):
    for file in files:
        if file.endswith(".md"):
            md_path = os.path.join(root, file)
            rel_md = os.path.relpath(md_path, "GEMINI")
            pm_path = os.path.join("share/shutter/perl/Shutter", rel_md.replace(".md", ".pm"))
            
            package, deps, methods = parse_pm(pm_path)
            
            if not package:
                package = "Shutter::" + rel_md.replace(".md", "").replace("/", "::")
            
            content = f"# {package}\n\n"
            content += f"**File Path:** `{pm_path}`\n\n"
            
            content += "## Description\n"
            content += f"Documentation for `{package}`. This module handles functionality related to {package.split('::')[-1]}.\n\n"
            
            if deps:
                content += "## Dependencies\n"
                for d in sorted(deps):
                    if d:
                        content += f"- `{d}`\n"
                content += "\n"
                
            if methods:
                content += "## Methods\n"
                for m in sorted(methods):
                    content += f"- `{m}`\n"
                content += "\n"
                
            with open(md_path, "w") as f:
                f.write(content)

print("Generated documentation for all GEMINI/*.md files.")
