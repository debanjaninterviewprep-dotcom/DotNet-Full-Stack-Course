# P6 — Defense in Depth: Design Review (Public Shared Task Board)

See [Practice-Problems.md](../Practice-Problems.md) P6 for the full requirement list.

## TODO: your design review here

### 1. Injection surface

- Every place user input reaches this feature, and how each is neutralised:

### 2. Least privilege

- Proposed login/role for this feature, exactly what it can/cannot access, and why
  view/procedure-based grants:

### 3. Data exposure

- Columns that must NEVER be reachable, and the specific mechanism (view exclusion /
  masking / no access at all) for each:

### 4. Rate limiting / abuse

- Why this is primarily an application/infrastructure concern:
- The one database-level safeguard still relevant:

### 5. Auditing

- Would you enable SQL Server Audit for this access path? Justify either way:
