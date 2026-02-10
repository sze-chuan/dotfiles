---
name: ui-developer-skill
description: "Guides deprecation and migration of API endpoints in the EdgeOS UI codebase. Use when removing, replacing, or migrating API endpoints across service layers, callers, tests, and OpenAPI specs."
---

# EdgeOS UI API Endpoint Migration

## Workflow

### 1. Scope the change
- Grep for all usages of the method being removed across production and test code
- Trace the call chain: generated API client → service impl → abstract service → service wrapper → views/components

### 2. Update service layer (bottom-up)
1. **Abstract service**: Remove old method, update replacement method signature
2. **Service impl**: Remove old implementation, update replacement to accept new parameters
3. **Service wrapper**: Replace old convenience methods. If migrating from unpaginated to paginated API, add a paging helper that collects all results

### 3. Update callers
- Migrate all production callers to the new method
- Drop parameters that don't exist in the new API

### 4. Update OpenAPI spec
- Remove the deprecated operation from `api/api-{service}/src/main/resources/`
- Remove response models no longer referenced anywhere in the spec
- Keep shared models still referenced by other operations/models

### 5. Clean up
- Remove unused converter methods and imports (production and test)
- Verify: `mvn compile -Ptest-only -o`

### 6. Update tests
- Remove tests for deleted methods
- Update mocks to match new method signatures
- Run: `mvn test -Ptest-only -o`

### 7. Commit and PR
- Commit production and test code separately
- Use the project PR template (`.github/pull_request_template.md`)

## Key conventions
- Service pattern: generated API → `{Service}V1` → `{Service}` (abstract) → wrapper → views
- Use `ServiceFactory` to obtain service instances
- Generated API clients under `api/api-{service}/` are not manually edited
- Use `mvn package -Pfull-build` when API specs change
