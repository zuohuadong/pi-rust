# Claude/Codex harness profile

This profile keeps the `rpi` core at the pinned `v0.8.4` release and adds the
existing extension packages that cover the harness surfaces described by the
Claude Code and Codex designs. The extensions remain outside the core runtime:
MCP connects external systems, Skills provide task instructions, hooks enforce
runtime checks, and the host owns session state and approvals.

## Pinned baseline

| Component | Version | Role |
| --- | --- | --- |
| `pi-rust` / `rpi` | `v0.8.4` | Agent loop, harness, TUI, remote protocol and plugin ABI |
| `rpi-mcp-adapter` | `v0.2.4` | MCP stdio and Streamable HTTP tools/resources |
| `rpi-subagents` | `v0.1.9` | Isolated child-agent delegation |
| `rpi-plan-mode` | `v0.1.6` | Plan mode and plan lifecycle |
| `rpi-permission-gate` | `v0.1.2` | Interactive allow/deny approval for mutating tools |
| `rpi-permissions` | `v0.1.9` | Persistent project/global permission rules |
| `rpi-todo` | `v0.2.4` | Persistent task tracking |
| `rpi-websearch` | `v0.1.6` | Optional web search MCP-style tool |
| `rpi-webfetch` | `v0.1.6` | Optional web retrieval tool |

The versions above are the compatibility baseline for this profile. Upgrade
the host and packages together after running the package smoke tests; the
plugin ABI is a runtime boundary and should not be upgraded independently.

## Install

```bash
rpi install rpi-mcp-adapter --version 0.2.4
rpi install rpi-subagents --version 0.1.9
rpi install rpi-plan-mode --version 0.1.6
rpi install rpi-permission-gate --version 0.1.2
rpi install rpi-permissions --version 0.1.9
rpi install rpi-todo --version 0.2.4
```

Enable interactive approvals for a terminal session with:

```bash
rpi --permission-gate
```

Keep the gate disabled for headless jobs unless the client implements the UI
dialog protocol. Headless jobs should use a saved allow/deny policy and fail
closed for tools outside that policy.

## MCP configuration

Create `.rpi/mcp.json` in the project. The file contains connection metadata,
not credentials committed to the repository. Environment variables should carry
secrets into a stdio server.

```json
{
  "mcpServers": {
    "browser": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"],
      "timeout": 60
    },
    "docs": {
      "url": "http://127.0.0.1:8931/mcp",
      "headers": {}
    }
  }
}
```

Use `mcp_list` to discover schemas, `mcp_call` for normal tool calls, and
`mcp_resource` for read/subscribe resource operations. MCP write operations
must still pass the host `before_tool_call` approval hook.

## Mapping to the two reference designs

| Harness requirement | `rpi` implementation |
| --- | --- |
| Scoped instructions | `AGENTS.md` / `CLAUDE.md` context-file loader |
| Skills | `rpi-harness` Skill loader and `.pi/skills` resources |
| MCP | `rpi-mcp-adapter` extension |
| Pre-tool policy | `BeforeToolCall` plus `rpi-permission-gate` / `rpi-permissions` |
| Post-tool verification | `AfterToolCall` and `AfterToolResults` hooks |
| Stop verification | `ShouldStopAfterTurn` hook |
| Compaction | `rpi-harness` compaction and `/compact` |
| Resume / fork | JSONL session tree and `/resume` / `/fork` |
| Subagents | `rpi-subagents` with host capability narrowing |
| `exec --json` | `rpi --mode json` event stream |
| App-server / remote | RPC protocol, `--server`, and `--connect` |
| Offline tests | `rpi-ai` faux provider and in-memory execution environment |

## Office connector rule

GitHub, browser, calendar, mail, document and spreadsheet integrations should be
separate MCP servers or extension packages. The core harness should only own
tool schemas, lifecycle, policy, cancellation, results and audit events. This
keeps credentials and vendor-specific failures outside the agent loop and lets
the same office connector work with the CLI, desktop app and remote client.

The first office acceptance slice is intentionally narrow:

1. read/search operations work without approval;
2. draft operations produce a reviewable artifact;
3. send/delete/publish operations require approval;
4. the session records the tool call, decision, result and verification;
5. a failed connector is reported as a failed tool result and is never replayed
   automatically.

## Verification

Run the core and package checks from their respective repositories:

```bash
cargo test --workspace --locked
cargo test -p rpi-mcp-adapter -p rpi-permission-gate -p rpi-permissions -p rpi-subagents --locked
cargo clippy -p rpi-mcp-adapter --all-targets --locked -- -D warnings
```

The package smoke harness must load the built MCP DLL through the real host ABI
before treating MCP support as delivered. A passing unit test alone does not
prove host/plugin compatibility.
