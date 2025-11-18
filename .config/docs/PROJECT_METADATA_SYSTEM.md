# Project Metadata System (LDAK for Projects)

**Status**: Active
**Created**: 2025-11-16
**Philosophy**: Zettelkasten principles applied to project management

## Core Principle

> **Folders = Storage (flat) | Metadata = Relationships (networked) | Tools = Views (dynamic)**

Projects are atomic units with metadata that defines relationships, not hierarchical folders.

---

## Problem Statement

Traditional hierarchical project organization fails because:

1. **Multi-dimensional relationships**: Projects belong to multiple categories (company, client, tech stack, domain)
2. **Temporal changes**: Ownership evolves (e.g., dojo: WM → DataKai, but WM gets perpetual license)
3. **Network effects**: Partnerships, 50/50 splits, client hierarchies
4. **Query limitations**: Can't easily answer "all databricks projects" or "all WM client work"

**Example**: Where does `dojo` live?
- `projects/datakai/dojo/` (current owner)
- `projects/westmonroe/dojo/` (partner with perpetual license)
- `projects/products/dojo/` (it's a product, not client work)

All are valid! Hierarchy forces a single choice.

---

## Solution: Flat + Metadata

### Directory Structure

```
~/projects/  ← All active projects, FLAT
├── cert-study-platform/
├── boardgamefinder/
├── dojo/
├── dbx-data-integration-hub/
├── adventure-works/
├── keplr-data-model/
└── tdp-sap-msk/

~/archive/  ← Completed projects
└── trulieve/
    └── tdp-sap-msk-v1/

~/scriptorium/  ← Knowledge (uses PARA)
└── 10-projects/
    ├── datakai/
    │   └── dojo/
    └── westmonroe/
        └── expresspros-dih/
```

**Key**: Code projects are flat. Knowledge in scriptorium uses PARA. They link via metadata.

---

## Metadata Schema: `.project.toml`

Every project root contains `.project.toml`:

### Template

```toml
[project]
name = "Project Display Name"
id = "project-slug"              # Must match directory name
status = "active"                 # active, paused, completed, archived
type = "product"                  # product, client-project, internal, experiment

[ownership]
primary = "datakai"               # datakai, westmonroe, personal
partners = []                     # Array of partners
license_model = ""                # exclusive, perpetual, shared, ""

[client]
# Only for client projects (type = "client-project")
end_client = ""                   # The actual client
intermediary = ""                 # Who connects you to client
my_role = ""                      # employee, contractor, partner, owner

[tech]
stack = []                        # Technologies used
domain = []                       # Business domains

[dates]
started = "YYYY-MM-DD"
completed = ""                    # Empty if active

[links]
scriptorium_project = ""          # Path in scriptorium
repository = ""                   # Git remote URL
documentation = ""                # Docs URL if exists
conduit_graph = ""                # Conduit knowledge graph ID (future)

[notes]
# Freeform notes
description = ""
```

### Example: DataKai Product

```toml
# ~/projects/dojo/.project.toml

[project]
name = "Dojo - AI Learning Platform"
id = "dojo"
status = "active"
type = "product"

[ownership]
primary = "datakai"
partners = ["westmonroe"]
license_model = "perpetual"

[client]
end_client = ""
intermediary = ""
my_role = "owner"

[tech]
stack = ["python", "fastapi", "react", "postgresql"]
domain = ["ai", "education", "certification-prep"]

[dates]
started = "2025-01-15"
completed = ""

[links]
scriptorium_project = "10-projects/datakai/dojo"
repository = "git@github.com:datakai/dojo.git"
documentation = "https://docs.dojo.datakai.net"
conduit_graph = ""

[notes]
description = "AI-powered certification study platform. Initially developed under WM, moved to DataKai with perpetual WM license for partnership."
```

### Example: Client Project

```toml
# ~/projects/dbx-data-integration-hub/.project.toml

[project]
name = "Databricks Data Integration Hub"
id = "dbx-data-integration-hub"
status = "active"
type = "client-project"

[ownership]
primary = "westmonroe"
partners = []
license_model = "exclusive"

[client]
end_client = "expresspros"
intermediary = "westmonroe"
my_role = "contractor"

[tech]
stack = ["databricks", "python", "spark", "delta-lake"]
domain = ["data-engineering", "integration", "etl"]

[dates]
started = "2025-08-21"
completed = ""

[links]
scriptorium_project = "10-projects/westmonroe/expresspros-dih"
repository = "git@github.com-wm:westmonroe/expresspros-dih.git"
documentation = ""
conduit_graph = ""

[notes]
description = "Low-latency data integration hub for ExpressPros recruiting data."
```

---

## Integration Points

### 1. Git Configuration

Auto-set git identity based on `ownership.primary`:

```bash
# In .gitconfig
[includeIf "hasconfig:remote.*.url:*datakai*"]
    path = ~/.config/git/gitconfig-datakai

[includeIf "hasconfig:remote.*.url:*westmonroe*"]
    path = ~/.config/git/gitconfig-westmonroe
```

Or read `.project.toml` directly (future enhancement).

### 2. Tmux Sessionizer

Update `tmux-sessionizer` to:
- Read `.project.toml` if exists
- Show metadata in fzf preview:
  ```
  dojo
    DataKai product (partner: WestMonroe)
    Status: Active | Started: 2025-01-15
    Stack: Python, FastAPI, React
  ```

### 3. Scriptorium Linking

In scriptorium project notes, add frontmatter:

```markdown
---
project_id: dojo
project_path: ~/projects/dojo
project_status: active
---

# Dojo Project Notes

[Link to code](~/projects/dojo)
```

Bidirectional linking:
- Code → Knowledge: `.project.toml` has `scriptorium_project`
- Knowledge → Code: Note frontmatter has `project_id` + `project_path`

### 4. Project CLI Tool

```bash
# List projects
project list                              # All active
project list --owner datakai              # DataKai projects
project list --client expresspros         # ExpressPros work
project list --tech databricks            # All Databricks projects
project list --status paused              # Paused projects

# Show project
project show dojo                         # Display metadata

# Edit metadata
project edit dojo                         # Open in $EDITOR

# Create new project
project new my-project --type product --owner datakai

# Archive project
project archive tdp-sap-msk               # Moves to ~/archive/

# Search
project search "ai education"             # Full-text search

# Stats
project stats                             # Summary by owner, status, tech
```

### 5. MCP Server (Future)

Scriptorium MCP could have:

```
/project list --owner datakai
/project show dojo
/project create my-new-project
```

Accessible in Claude Code sessions!

### 6. Conduit Integration (Future)

Each project becomes a node in Conduit knowledge graph:

```
(Project:dojo)-[:OWNED_BY]->(Company:datakai)
(Project:dojo)-[:PARTNERS_WITH]->(Company:westmonroe)
(Project:dojo)-[:USES_TECH]->(Tech:python)
(Project:dojo)-[:DOCUMENTED_IN]->(Note:scriptorium/10-projects/datakai/dojo)
```

Query across code + knowledge seamlessly.

---

## Workflow Examples

### New DataKai Project

```bash
cd ~/projects
git clone git@github.com:datakai/new-project.git
cd new-project

# Copy template
cp ~/.config/templates/.project.toml .project.toml

# Edit metadata
nvim .project.toml
# Set: primary=datakai, type=product, etc.

# Create scriptorium notes
cd ~/scriptorium
mkdir -p 10-projects/datakai/new-project/notes
nvim 10-projects/datakai/new-project/notes/overview.md

# Link them
# In .project.toml: scriptorium_project = "10-projects/datakai/new-project"
# In overview.md: project_id: new-project
```

### Client Project via WestMonroe

```bash
cd ~/projects
git clone git@github.com-wm:westmonroe/client-project.git
cd client-project

cp ~/.config/templates/.project.toml .project.toml
nvim .project.toml
# Set:
#   primary = "westmonroe"
#   end_client = "client-name"
#   intermediary = "westmonroe"
#   my_role = "contractor"

# Scriptorium notes
cd ~/scriptorium
mkdir -p 10-projects/westmonroe/client-project/notes
```

### Project Transitions (Dojo Example)

**Initial**: Dojo developed under WM
```toml
[ownership]
primary = "westmonroe"
```

**Transition**: Moved to DataKai with WM perpetual license
```toml
[ownership]
primary = "datakai"
partners = ["westmonroe"]
license_model = "perpetual"

[notes]
description = "Originally developed under WM. Transitioned to DataKai 2025-03-15 with perpetual WM license for partnership."
```

Git tracks the change! History preserved.

### Finding Projects

```bash
# What DataKai products are active?
project list --owner datakai --type product --status active

# What client work am I doing through WM?
project list --intermediary westmonroe

# What projects use Databricks?
project list --tech databricks

# When did I start working on ExpressPros stuff?
project show dbx-data-integration-hub | grep started
```

---

## Migration Plan

### Phase 1: Foundation (Now)
1. ✅ Document system
2. ✅ Create `.project.toml` template
3. Flatten `~/projects/` (move subdirs up one level)
4. Add `.project.toml` to 3-5 key projects manually
5. Test with sessionizer

### Phase 2: Tooling (Week 1)
1. Build `project` CLI in Python
   - `project list` with filters
   - `project show`
   - `project new` from template
2. Update sessionizer fzf preview
3. Add git pre-commit hook to validate `.project.toml`

### Phase 3: Integration (Week 2-3)
1. Scriptorium bidirectional linking
2. Auto git-config from `.project.toml`
3. MCP server `/project` commands
4. Archive old projects

### Phase 4: Advanced (Month 1+)
1. Conduit knowledge graph ingestion
2. Time tracking integration
3. Project templates (cookiecutter-style)
4. Client invoicing from metadata

---

## Design Decisions

### Why TOML?
- Human readable/editable
- Structured (not just frontmatter)
- Python/Rust tooling available
- Git-friendly (clear diffs)

### Why Flat Structure?
- Sessionizer finds all projects easily
- No arbitrary hierarchy decisions
- Move projects freely (just update metadata)
- Works with any future taxonomy

### Why Bidirectional Links?
- Code doesn't depend on knowledge (can work standalone)
- Knowledge doesn't depend on code (can survive project archival)
- But they reference each other for full context

### Why NOT Databases?
- Files = version controlled
- Files = portable
- Files = transparent
- Files = no additional infrastructure
- Can always build DB views later

---

## Best Practices

### Metadata Hygiene

1. **Always set `id` to match directory name**
2. **Keep `status` current** (active/paused/completed)
3. **Update `partners` when ownership changes**
4. **Fill `started` date** (helps with project history)
5. **Use `notes.description`** for context (future you will thank you)

### Git Considerations

**Should `.project.toml` be committed?**

**YES if**:
- Team project (everyone needs metadata)
- Open source (helps contributors understand context)

**NO if**:
- Personal metadata (your client relationships)
- Sensitive info (partnership details)

**Solution**: Gitignore and store separately, OR commit with sanitized data.

### Scriptorium Sync

When project status changes:
1. Update `.project.toml` status
2. Move scriptorium notes to archive if completed:
   - `10-projects/datakai/old-project/` → `40-archive/datakai/old-project/`
3. Update frontmatter in notes

---

## Tools Stack

### Current
- TOML files (manual editing)
- Tmux sessionizer (reads metadata)
- Git (version control)

### Phase 2
- Python CLI (`project` command)
- Fzf preview enhancements
- Git hooks (validation)

### Future
- MCP server (Claude integration)
- Conduit ingestion (knowledge graphs)
- Web dashboard (visual project explorer)

---

## Related Systems

- **Scriptorium PARA**: Knowledge management
- **Zettelkasten**: Atomic notes with links
- **Conduit**: Knowledge graph engine
- **LDAK**: Linked Data Architecture for Knowledge
- **Git Conditional Includes**: Auto identity switching

---

## Success Metrics

You'll know this is working when:

1. ✅ You can answer "what DataKai projects am I working on?" instantly
2. ✅ Moving a project (like dojo) doesn't require reorganizing files
3. ✅ Sessionizer shows project context without opening it
4. ✅ Git commits use the right identity automatically
5. ✅ You can find all Databricks work across clients
6. ✅ Project knowledge and code are clearly linked

---

## Future Enhancements

### Project Templates
```bash
project new my-app --template datakai-fastapi-react
# Creates project with .project.toml pre-filled
```

### Time Tracking
```toml
[tracking]
estimated_hours = 40
actual_hours = 52
billable = true
rate = 150
```

### Dependencies
```toml
[dependencies]
requires = ["cert-study-platform"]  # Depends on other projects
used_by = ["conduit"]               # Used by these projects
```

### Tags
```toml
[tags]
labels = ["mvp", "poc", "production", "maintenance"]
```

---

## Maintenance

**Review quarterly**:
- Archive completed projects
- Update partner relationships
- Audit metadata accuracy
- Clean up orphaned scriptorium notes

**Version this document**:
- Track changes in git
- Date updates
- Keep migration history

---

## Questions & Answers

**Q: What about multi-repo projects?**
A: Main project has `.project.toml`. Sub-repos reference parent:
```toml
[project]
parent_project = "cert-study-platform"
```

**Q: Private vs public metadata?**
A: Use `.project.local.toml` (gitignored) for sensitive data. Merge at query time.

**Q: How to handle experiments?**
A: `type = "experiment"`, move to archive or delete when done.

**Q: Client onboarding/offboarding?**
A: Update `status`, move code to archive, preserve knowledge in scriptorium.

---

**Last Updated**: 2025-11-16
**Maintained By**: hstecher
**Location**: `~/.config/docs/PROJECT_METADATA_SYSTEM.md`
