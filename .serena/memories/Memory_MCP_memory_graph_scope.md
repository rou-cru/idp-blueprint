# Memory Graph Scope

- **Focus:** Model deployable entities, architectural concepts, and DocPages that explain them. Each node should help traverse from a capability → its implementation → the page describing it.
- **Exclude:**
  - Navigation scaffolding (DocSection, DocumentationWebsite, etc.). MKDocs already defines structure.
  - Audit/verification/gap trackers ("Veracidad_*", "*_Gap", "Documentation Audit", etc.). They age fast and don’t describe the system.
  - Detailed runtime settings (resource limits, rolling updates) that belong in values.yaml.
  - Personal workflow rules (commit style, lint reminders, etc.).
- **Observation style:** short facts (role, path, namespace) with code/doc references. Avoid speculating or duplicating config.
- **Connectivity:** every node must link to either a deployable, concept, or documentation node to keep the graph traversable—no floating subgraphs.