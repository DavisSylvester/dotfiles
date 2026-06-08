#!/usr/bin/env bash
# Status line for Claude Code. Reads session JSON on stdin, prints
# "dir | model | ctx: N% | prompt: X | session: Y | cost: $Z".
#   - prompt:  tokens currently in the context window (the live prompt)
#   - session: cumulative tokens spent across the whole session (summed from the transcript)
#   - cost:    estimated session cost in USD (Claude Code client-side estimate)
# Uses node (present on all machines) instead of jq, so it works on macOS/Linux/Windows
# without an external dependency.
node -e '
  const fs = require("fs");
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

    const fmt = (n) => {
      if (n == null || isNaN(n)) return null;
      if (n >= 1e6) return (n / 1e6).toFixed(1).replace(/\.0$/, "") + "M";
      if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.0$/, "") + "k";
      return String(Math.round(n));
    };

    // Tokens currently in the context window (the live prompt).
    const cw = j.context_window || {};
    const promptTokens = (cw.total_input_tokens || 0) + (cw.total_output_tokens || 0);
    const prompt = promptTokens > 0 ? ` | prompt: ${fmt(promptTokens)}` : "";

    // Cumulative tokens spent across the whole session, summed from the transcript.
    let sessionTokens = 0;
    let tp = j.transcript_path;
    // Normalize MSYS/git-bash style paths (e.g. /c/Users/...) to Windows form.
    if (tp && /^\/[a-zA-Z]\//.test(tp)) {
      tp = tp[1].toUpperCase() + ":" + tp.slice(2);
    }
    if (tp) {
      try {
        const lines = fs.readFileSync(tp, "utf8").split(/\r?\n/);
        for (const line of lines) {
          if (!line) continue;
          let e;
          try { e = JSON.parse(line); } catch { continue; }
          const u = (e && e.usage) || (e && e.message && e.message.usage);
          if (u) {
            // Exclude cache_read_input_tokens so the total reflects new work,
            // not the cached context re-sent on every turn.
            sessionTokens += (u.input_tokens || 0)
              + (u.output_tokens || 0)
              + (u.cache_creation_input_tokens || 0);
          }
        }
      } catch {}
    }
    const session = sessionTokens > 0 ? ` | session: ${fmt(sessionTokens)}` : "";

    // Estimated session cost in USD (client-side estimate at API list prices).
    const costUsd = j.cost && j.cost.total_cost_usd;
    const cost = costUsd != null && costUsd !== "" ? ` | cost: $${Number(costUsd).toFixed(2)}` : "";

    process.stdout.write(`${dir} | ${model}${ctx}${prompt}${session}${cost}`);
  });
'
