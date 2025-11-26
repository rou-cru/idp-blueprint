#!/bin/bash
set -e

# Check if d2 is installed
if ! command -v d2 &> /dev/null; then
    echo "Error: d2 is not installed. Please install it from https://d2lang.com/tour/install"
    exit 1
fi

echo "🔍 Finding D2 diagrams..."

# Find all .d2 files in Docs directory
find Docs/src/content/docs -name "*.d2" | while read -r file; do
    outfile="${file%.d2}.svg"
    
    # Check if rebuild is needed (if svg doesn't exist or d2 is newer)
    if [ ! -f "$outfile" ] || [ "$file" -nt "$outfile" ]; then
        echo "🎨 Rendering $file -> $outfile"
        d2 "$file" "$outfile" > /dev/null
    else
        echo "✨ Up to date: $outfile"
    fi
done

echo "✅ All diagrams rendered."
