import os

with open("ARCHITECTURE.md", "r") as f:
    arch_lines = f.readlines()

existing_pms = [word.strip("`| ") for line in arch_lines for word in line.split() if word.endswith(".pm")]

missing = {}
for root, _, files in os.walk("share/shutter/perl/Shutter"):
    for file in files:
        if file.endswith(".pm"):
            if file not in existing_pms:
                rel_path = os.path.relpath(os.path.join(root, file), "share/shutter/perl/Shutter")
                gemini_link = "GEMINI/" + rel_path.replace(".pm", ".md")
                
                # Group by root
                group = os.path.relpath(root, "share/shutter/perl/Shutter")
                if group not in missing:
                    missing[group] = []
                missing[group].append(f"| `{file}` | TODO | [View]({gemini_link}) |")

for group, lines in missing.items():
    print(f"\n### {group}")
    for l in sorted(lines):
        print(l)
