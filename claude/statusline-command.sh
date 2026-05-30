#!/usr/bin/env bash
# Status line for Claude Code. Reads session JSON on stdin, prints "dir | model | ctx: N%".
# Uses node (present on all machines) instead of jq, so it works on macOS/Linux/Windows
# without an external dependency.
node -e '
  let raw = "";
  process.stdin.on("data", (d) => (raw += d));
  process.stdin.on("end", () => {
    let j = {};
    try { j = JSON.parse(raw); } catch {}
    const cwd = (j.workspace && j.workspace.current_dir) || j.cwd || "";
    const model = (j.model && j.model.display_name) || "";
    const used = j.context_window && j.context_window.used_percentage;
    const p = cwd.split(/[\\/]+/).filter(Boolean);
    const dir = p.length <= 1 ? (p[0] || "/") : p.slice(-2).join("/");
    const ctx = used != null && used !== "" ? ` | ctx: ${Math.round(used)}%` : "";
    process.stdout.write(`${dir} | ${model}${ctx}`);
  });
'
