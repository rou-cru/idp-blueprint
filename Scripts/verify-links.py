import os
import re
from pathlib import Path

DOCS_ROOT = Path("Docs/src/content/docs")
ASSETS_ROOT = Path("Docs/src/assets")

link_pattern = re.compile(r'\[.*?\]\((.*?)\)')
image_pattern = re.compile(r'!\[.*?\]\((.*?)\)')

errors = []

def check_link(file_path, link, link_type):
    # Ignore external links
    if link.startswith("http") or link.startswith("mailto:"):
        return

    # Ignore anchors for now (or handle them simply)
    anchor = ""
    if "#" in link:
        link, anchor = link.split("#", 1)

    if not link:
        # Link was just an anchor like "#section"
        return

    # Resolve path
    if link.startswith("/"):
        # Absolute path relative to site root (usually docs root)
        # Adjust based on how Astro handles absolute paths if needed
        # For now assuming /path maps to DOCS_ROOT/path
        target_path = DOCS_ROOT / link.lstrip("/")
    else:
        # Relative path
        target_path = (file_path.parent / link).resolve()

    # Check if file exists
    # Try with .md, .mdx extensions if not present
    if not target_path.exists():
        # Try appending extensions
        found = False
        for ext in [".md", ".mdx", ".png", ".svg", ".jpg", ".webp"]:
            if target_path.with_suffix(ext).exists():
                found = True
                break
            # Also check if it's a directory (index.md)
            if target_path.is_dir() and (target_path / ("index" + ext)).exists():
                found = True
                break
        
        if not found:
             # Check assets
             if "assets" in str(target_path):
                 # Try to resolve against actual assets dir if the relative path went there
                 pass

             errors.append(f"{file_path}: Broken {link_type}: {link} (resolved: {target_path})")

def scan_file(file_path):
    try:
        content = file_path.read_text()
    except Exception as e:
        errors.append(f"Could not read {file_path}: {e}")
        return

    for match in link_pattern.finditer(content):
        check_link(file_path, match.group(1), "link")
    
    for match in image_pattern.finditer(content):
        check_link(file_path, match.group(1), "image")

def main():
    print(f"Scanning {DOCS_ROOT}...")
    for ext in ["*.md", "*.mdx"]:
        for file_path in DOCS_ROOT.rglob(ext):
            scan_file(file_path)

    if errors:
        print(f"Found {len(errors)} broken links:")
        for e in errors:
            print(e)
        exit(1)
    else:
        print("No broken links found!")

if __name__ == "__main__":
    main()
