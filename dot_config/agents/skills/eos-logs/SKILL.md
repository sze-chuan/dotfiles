---
name: eos-logs
description: "Guides investigation of EdgeOS bundled logs. Use when extracting, filtering, or analysing logs for a specific EdgeOS service from all.logs or related log archives."
---

# EdgeOS Log Investigation

## Log location

The working directory is the unpacked bundle, e.g.:
```
/usr/local/illumina/logs/edgeos/
```

Key files:

| File | Description |
|---|---|
| `all.logs` | Main aggregated log file (JSON-per-line) |
| `all.logs-*.gz` | Rotated/archived log files |
| `audit.logs` | Audit trail |
| `install.log` | Installation log |
| upgrade.log | Upgrade log |

## Log format

Each line is a JSON object. Key fields:

```json
{
  "source": "/var/log/containers/<pod>_<namespace>_<container>-<hash>.log",
  "time": "<RFC3339 timestamp with local offset>",
  "stream": "stdout|stderr",
  "logtag": "F",
  "level": "Information|Warning|Error|...",
  "log": "<raw container log line for non-structured containers>",
  ...
}
```

- **Structured logs** (e.g. ASP.NET / .NET apps): extra fields like `level`, `SourceContext`, `EventId`, `log.description` are present at the top level.
- **Unstructured logs** (e.g. Traefik, system containers): the raw line is in the `"log"` field, with embedded key=value pairs like `level=error msg="..."`.

## Workflow

### 1. Extract service logs

Always filter by **container name** first, not service name, to avoid capturing noise from other services that merely reference the service name in their own logs.

The container name pattern in the `source` field is:
```
/var/log/containers/<pod-name>_<namespace>_<container-name>-<hash>.log
```

Extract by matching the pod name prefix:

```bash
grep '"source":"/var/log/containers/<service-name>' all.logs > <service-name>.logs
wc -l <service-name>.logs
```

**Example** — extract `edgeos-ims` logs:
```bash
grep '"source":"/var/log/containers/edgeos-ims' all.logs > edgeos-ims.logs
wc -l edgeos-ims.logs
```

This ensures only logs from pods whose name starts with `edgeos-ims` are captured, not from other pods that happen to mention `edgeos-ims` in their log messages.

### 2. Identify containers within the service

A single service pod can have multiple containers (init containers, sidecars, main app). List them:

```bash
grep -oE '"source":"[^"]*"' <service>.logs | sort -u
```

Common containers in EdgeOS services:
- `<service>` — main application container
- `db-init` — database migration init container
- `keycloak-aliveness-check` — Keycloak readiness sidecar
- `update-ca-certs` — certificate update init container

### 3. Find errors

**Count all error-bearing lines:**
```bash
grep -ic 'error\|fatal\|exception\|critical' <service>.logs
```

**Structured log errors** (level field in JSON):
```bash
grep '"level":"Error"' <service>.logs
```

**Unstructured log errors** (Traefik-style):
```bash
grep 'level=error' <service>.logs
```

**Scoped to main app container only** (exclude init/sidecar noise):
```bash
grep '"source":"/var/log/containers/<service>.*_default_<container>-' <service>.logs \
  | grep -i 'error\|fatal'
```

### 4. Summarise errors by frequency

Extract and deduplicate error messages:

**Structured (JSON `"log".description` or top-level message):**
```bash
grep '"level":"Error"' <service>.logs \
  | grep -oE '"message":"[^"]*"' | sort | uniq -c | sort -rn | head -20
```

**Unstructured (Traefik-style `msg=`):**
```bash
grep 'level=error' <service>.logs \
  | grep -oE 'level=error msg=\\"[^\\"]*\\"' | sort | uniq -c | sort -rn
```

### 5. Check log levels distribution

```bash
grep -oE '"level":"[^"]*"' <service>.logs | sort | uniq -c | sort -rn
```

### 6. Get time range

```bash
grep -oE '"time":"[^"]*"' <service>.logs | sort | head -1  # earliest
grep -oE '"time":"[^"]*"' <service>.logs | sort | tail -1  # latest
```

### 7. Break down errors by source container

```bash
grep -i 'error\|fatal' <service>.logs \
  | grep -oE '"source":"[^"]*"' | sort | uniq -c | sort -rn | head -10
```

## Common EdgeOS error patterns

| Error | Component | Meaning |
|---|---|---|
| `Cannot create service: subset not found` | Traefik | No healthy endpoints registered for the service; pod not ready or node missing |
| `FailedToUpdateEndpointSlices: node "X" not found` | endpoint-slice-controller | Node removed from cluster; endpoint slice update failed |
| `UsingEphemeralFileSystemLocationInContainer` | ASP.NET DataProtection | Keys stored in non-persistent path inside container (Warning, not critical) |
| `NoXMLEncryptorConfiguredKeyMayBePersistedToStorageInUnencryptedForm` | ASP.NET DataProtection | No XML encryptor configured (Warning, not critical) |

## Key notes

- **Traefik errors referencing a service do not originate from that service.** Always check the `source` field to identify which component logged the error.
- The bulk of "error" lines in a service's log extract often come from Traefik or the event-exporter, not the service itself.
- ASP.NET DataProtection warnings are expected in containerised deployments without persistent storage and are not actionable.
- Repeated `FailedToUpdateEndpointSlices` errors combined with Traefik `subset not found` errors typically indicate a **node failure** or **pod scheduling issue**, not an application bug.
