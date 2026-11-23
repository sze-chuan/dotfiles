#!/bin/sh
# Merge Claude Code MCP servers into ~/.claude.json (user scope).
# Only the mcpServers key is touched; other Claude state is preserved.
# Re-runs whenever this file changes (chezmoi run_onchange).
python3 - <<'PY'
import json, os

path = os.path.expanduser("~/.claude.json")
servers = {
    "executor": {"command": "executor", "args": ["mcp"]},
}

with open(path) as f:
    data = json.load(f)

data.setdefault("mcpServers", {}).update(servers)

tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.chmod(tmp, 0o600)
os.replace(tmp, path)
PY
