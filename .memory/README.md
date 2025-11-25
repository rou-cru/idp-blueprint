# Knowledge Graph Database

**File:** `graph.db` (SQLite database)

This is an **LLM-agnostic** knowledge graph containing the architectural structure of the IDP-Blueprint project. It enables AI assistants to answer queries without reading files.

## Why This Exists

Traditional documentation requires reading multiple files to answer simple questions like:
- "What version of Vault is deployed?" → Need to grep values files
- "Which components are Stateful?" → Need to understand architecture docs
- "What chart deploys ArgoCD?" → Need to map Helm releases to apps

This knowledge graph provides **instant answers** through graph traversal instead of file parsing.

## Database Contents

- **151 entities**: Components, Charts, Layers, Domains, Stacks
- **167 relations**: DEPLOYS, BELONGS_TO_LAYER, BELONGS_TO_DOMAIN, MANAGES, etc.
- **~600KB**: Optimized for minimal token usage

### Entity Types

- **Component**: Running applications (Vault, ArgoCD, Prometheus, etc.)
- **Helm-Chart**: Helm charts with version and repository info
- **Layer**: Infrastructure, Platform-Services, Control-Plane, User-Experience
- **Domain**: Observability, Security, Delivery
- **Stack**: Observability-Stack, Security-Stack, CI-CD-Stack

### Standard Observations (Components)

```
- version: "x.y.z"              # Application version
- namespace: "namespace-name"   # K8s namespace
- state: "Stateful|Stateless"   # Data persistence
- exposure: "Internal|Exposed"  # Network visibility
- deployment_type: "Deployment|StatefulSet|DaemonSet"
```

### Standard Observations (Charts)

```
- chart_version: "x.y.z"
- repository: "https://..."
- values_path: "path/to/values.yaml"
```

## Using This Graph

### Claude Code

The `.mcp.json` file in the project root configures the MCP memory server to use this database:

```json
{
  "mcpServers": {
    "memory": {
      "command": "memory-mcp-server-go",
      "args": ["-memory", "${workspaceFolder}/.memory/graph.db"]
    }
  }
}
```

### Gemini Code Assist / Other IDEs

Configure your MCP client to point to `.memory/graph.db` using the appropriate path variable for your IDE.

### Direct Queries (SQLite)

```bash
# List all components in Observability domain
sqlite3 .memory/graph.db << 'EOF'
SELECT e.name, e.entity_type
FROM entities e
JOIN relations r ON e.name = r.from_entity_id
WHERE r.to_entity_id = 'Domain:Observability'
  AND r.relation_type = 'BELONGS_TO_DOMAIN';
EOF

# Get version of Vault
sqlite3 .memory/graph.db << 'EOF'
SELECT content
FROM observations
WHERE entity_id = (SELECT id FROM entities WHERE name = 'Vault')
  AND content LIKE 'version:%';
EOF
```

## Updating the Graph

When making architectural changes (new component, version upgrade, etc.):

1. Update the graph using your AI assistant's memory tools
2. Changes are saved automatically to `.memory/graph.db`
3. Commit the updated database with your code changes
4. Other developers receive the updated graph on `git pull`

## Exporting to JSON

```bash
python3 << 'EOF'
import sqlite3, json

conn = sqlite3.connect('.memory/graph.db')
conn.row_factory = sqlite3.Row

# Export entities
entities = []
for row in conn.execute('SELECT name, entity_type FROM entities ORDER BY name'):
    entity = {"name": row['name'], "entityType": row['entity_type'], "observations": []}
    obs = conn.execute('SELECT content FROM observations WHERE entity_id = (SELECT id FROM entities WHERE name = ?)', (row['name'],))
    entity['observations'] = [o['content'] for o in obs]
    entities.append(entity)

# Export relations
relations = []
for row in conn.execute('''
    SELECT e1.name as from_name, e2.name as to_name, r.relation_type
    FROM relations r
    JOIN entities e1 ON r.from_entity_id = e1.id
    JOIN entities e2 ON r.to_entity_id = e2.id
    ORDER BY e1.name
'''):
    relations.append({"from": row['from_name'], "to": row['to_name'], "relationType": row['relation_type']})

with open('knowledge_graph_export.json', 'w') as f:
    json.dump({"entities": entities, "relations": relations}, f, indent=2)

conn.close()
print(f"✅ Exported {len(entities)} entities, {len(relations)} relations")
EOF
```

## Optimization Status

**Current**: ~60% optimized (see `../todo-clean-graph.md` for pending work)

### Pending Tasks

- 6 components need observation cleanup
- IDP-Blueprint entity needs reduction (~100 → <10 observations)
- 3 Stack entities need optimization
- Old Chart entities need deletion
- Abstract relation cleanup
