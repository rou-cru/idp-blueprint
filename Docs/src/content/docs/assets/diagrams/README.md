# D2 Diagrams

This directory contains all D2 diagram source files for the IDP Blueprint documentation.

## Directory Structure

```text
diagrams/
├── architecture/     # Architecture diagrams (observability, secrets, policies, etc.)
├── concepts/         # Conceptual diagrams (design philosophy, etc.)
└── reference/        # Reference diagrams (FinOps tags, etc.)
```

## Rendering Diagrams

To render all D2 files to SVG:

### Prerequisites

Install D2:

**macOS/Linux:**

```bash
brew install d2
```

**Windows:**

```powershell
winget install Terrastruct.D2
```

Or download from: <https://d2lang.com/tour/install>

### Render All Diagrams

Run the render script from the repository root:

```bash
# From repository root
./Scripts/render-diagrams.sh
```

Or manually render individual diagrams:

```bash
# Render a single diagram
d2 Docs/src/assets/diagrams/architecture/observability-dataflow.d2 \
   Docs/src/assets/diagrams/architecture/observability-dataflow.svg

# Render all in a directory
for file in Docs/src/assets/diagrams/**/*.d2; do
  d2 "$file" "${file%.d2}.svg"
done
```

### PowerShell (Windows)

```powershell
# Render all diagrams
Get-ChildItem -Path "Docs\src\assets\diagrams" -Recurse -Filter "*.d2" | ForEach-Object {
    $svgPath = $_.FullName -replace '\.d2$', '.svg'
    d2 $_.FullName $svgPath
}
```

## D2 Style Guide

All diagrams follow a consistent color scheme defined in classes:

| Class | Description | Fill | Stroke |
|-------|-------------|------|--------|
| `actor` | Users, Engineers | `#0f172a` | `#38bdf8` |
| `control` | Control Logic (ArgoCD, Controllers) | `#111827` | `#6366f1` |
| `infra` | Infrastructure (K8s, Clusters) | `#0f172a` | `#38bdf8` |
| `data` | Data/State (Vault, Git, DBs) | `#0f766e` | `#34d399` |
| `ui` | UI/Dashboards | `#7c3aed` | `#a855f7` |
| `ext` | External Systems | `#0f172a` | `#22d3ee` |

Example usage:

```
classes: {
  control: { style: { fill: "#111827"; stroke: "#6366f1"; font-color: white } }
}
Argo: { class: control; label: "ArgoCD" }
```

## Adding New Diagrams

1. Create a new `.d2` file in the appropriate subdirectory
2. Follow the style guide for consistent colors
3. Render to SVG using the script above
4. Reference the SVG in your markdown:

```markdown
![Diagram Title](../../../assets/diagrams/category/diagram-name.svg)

> **Source:** [diagram-name.d2](../../../assets/diagrams/category/diagram-name.d2)
```

## CI/CD Integration

The diagram rendering is integrated into the docs build process. When you commit a `.d2`
file, the CI pipeline automatically renders it to SVG.

See `.github/workflows/docs.yaml` for implementation details.
