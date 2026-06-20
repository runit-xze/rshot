import os

with open("ARCHITECTURE.md", "r") as f:
    arch_lines = f.readlines()

existing_pms = [word.strip("`| ") for line in arch_lines for word in line.split() if word.endswith(".pm")]

missing = {}
for root, _, files in os.walk("share/shutter/resources/modules/Shutter"):
    for file in files:
        if file.endswith(".pm"):
            if file not in existing_pms:
                rel_path = os.path.relpath(os.path.join(root, file), "share/shutter/resources/modules/Shutter")
                gemini_link = "GEMINI/" + rel_path.replace(".pm", ".md")
                
                group = os.path.relpath(root, "share/shutter/resources/modules/Shutter")
                if group not in missing:
                    missing[group] = []
                missing[group].append(f"| `{file}` | TODO | [View]({gemini_link}) |\n")

with open("ARCHITECTURE.md", "a") as f:
    f.write("\n## Additional Modules\n\n")
    for group in sorted(missing.keys()):
        lines = missing[group]
        f.write(f"### {group} Modules (`share/shutter/resources/modules/Shutter/{group}/`)\n\n")
        f.write("| Module | Purpose | GEMINI.md |\n")
        f.write("|--------|---------|-----------|\n")
        for l in sorted(lines):
            f.write(l)
        f.write("\n")
