#!/usr/bin/env node
/**
 * Render a DNS/domain operation summary into report.html + card.json.
 *
 * Usage:
 *   node render.mjs <details.json|-> [outDir]
 *   echo "$JSON" | node render.mjs - [outDir]
 *
 * Works under Node or Bun. See SKILL.md for the input schema.
 */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

const arg = process.argv[2];
const outDir = process.argv[3] ?? "dns-report";

if (!arg) {
  console.error("Usage: render.mjs <details.json|-> [outDir]");
  process.exit(1);
}

let raw;
try {
  // fd 0 is the portable way to read piped stdin on Windows, macOS and Linux.
  raw = arg === "-" ? readFileSync(0, "utf8") : readFileSync(arg, "utf8");
} catch (err) {
  console.error(`Could not read input ${arg === "-" ? "from stdin" : `file "${arg}"`}: ${err.message}`);
  process.exit(1);
}

let data;
try {
  data = JSON.parse(raw);
} catch (err) {
  console.error(`Input is not valid JSON: ${err.message}`);
  process.exit(1);
}

const status = String(data.status ?? "success").toLowerCase();
const PALETTE = {
  success: { color: "#16a34a", bg: "#f0fdf4", label: "SUCCESS", card: "good", emoji: "✅" },
  failure: { color: "#dc2626", bg: "#fef2f2", label: "FAILURE", card: "attention", emoji: "❌" },
  partial: { color: "#d97706", bg: "#fffbeb", label: "PARTIAL", card: "warning", emoji: "⚠️" },
};
const p = PALETTE[status] ?? { color: "#2563eb", bg: "#eff6ff", label: status.toUpperCase(), card: "accent", emoji: "ℹ️" };

const title = data.title ?? data.operation ?? "DNS operation";
const subtitleBits = [data.operation && data.operation !== title ? data.operation : null, data.domain]
  .filter(Boolean).join(" · ");
const ts = data.timestamp ?? "";
const actor = data.actor ?? "";
const inputs = Array.isArray(data.inputs) ? data.inputs : [];
const records = Array.isArray(data.records) ? data.records : [];
const result = data.result ?? {};
const resultFacts = Array.isArray(result.details) ? result.details : [];
const links = Array.isArray(result.links) ? result.links : (Array.isArray(data.links) ? data.links : []);
const error = data.error ?? "";

// regex replace (not String.replaceAll) for compatibility with older Node runtimes
const esc = (s) => String(s ?? "")
  .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

// ---------------------------------------------------------------- HTML
const factRows = (arr) => arr.map((f) =>
  `<tr><td style="padding:6px 14px 6px 0;color:#64748b;white-space:nowrap;vertical-align:top">${esc(f.label)}</td>` +
  `<td style="padding:6px 0;color:#0f172a;word-break:break-all">${esc(f.value)}</td></tr>`).join("");

const recordRows = records.map((r) =>
  `<tr>
     <td style="padding:8px 10px;border-bottom:1px solid #e2e8f0;font-family:ui-monospace,Consolas,monospace;word-break:break-all">${esc(r.name)}</td>
     <td style="padding:8px 10px;border-bottom:1px solid #e2e8f0"><span style="background:#eef2ff;color:#4338ca;border-radius:4px;padding:1px 8px;font-size:12px;font-weight:600">${esc(r.type)}</span></td>
     <td style="padding:8px 10px;border-bottom:1px solid #e2e8f0;font-family:ui-monospace,Consolas,monospace;word-break:break-all">${esc(r.value)}</td>
     <td style="padding:8px 10px;border-bottom:1px solid #e2e8f0;text-align:right">${esc(r.ttl ?? "-")}</td>
     <td style="padding:8px 10px;border-bottom:1px solid #e2e8f0">${esc(r.action ?? "")}</td>
   </tr>`).join("");

const section = (heading, inner) => inner
  ? `<tr><td style="padding:22px 28px 0"><div style="font-size:13px;font-weight:700;letter-spacing:.04em;text-transform:uppercase;color:#94a3b8;margin-bottom:8px">${esc(heading)}</div>${inner}</td></tr>`
  : "";

const html = `<!doctype html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;background:#f1f5f9;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#0f172a">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f1f5f9;padding:24px 0">
    <tr><td align="center">
      <table role="presentation" width="640" cellpadding="0" cellspacing="0" style="max-width:640px;width:100%;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 1px 3px rgba(0,0,0,.08)">
        <tr><td style="background:${p.bg};border-left:6px solid ${p.color};padding:20px 28px">
          <div style="display:inline-block;background:${p.color};color:#fff;border-radius:999px;padding:2px 12px;font-size:12px;font-weight:700;letter-spacing:.05em">${p.emoji} ${esc(p.label)}</div>
          <div style="font-size:20px;font-weight:700;margin-top:10px">${esc(title)}</div>
          ${subtitleBits ? `<div style="color:#64748b;font-size:14px;margin-top:2px">${esc(subtitleBits)}</div>` : ""}
        </td></tr>
        ${section("Inputs", inputs.length ? `<table role="presentation" cellpadding="0" cellspacing="0" style="font-size:14px">${factRows(inputs)}</table>` : "")}
        ${section("DNS records", records.length ? `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="font-size:13px;border-collapse:collapse">
            <tr style="color:#94a3b8;text-align:left;font-size:11px;text-transform:uppercase;letter-spacing:.04em">
              <th style="padding:0 10px 6px">Name</th><th style="padding:0 10px 6px">Type</th><th style="padding:0 10px 6px">Value</th><th style="padding:0 10px 6px;text-align:right">TTL</th><th style="padding:0 10px 6px">Action</th></tr>
            ${recordRows}</table>` : "")}
        ${section("Result", (result.summary || resultFacts.length) ? `
            ${result.summary ? `<div style="font-size:14px;margin-bottom:${resultFacts.length ? "10px" : "0"}">${esc(result.summary)}</div>` : ""}
            ${resultFacts.length ? `<table role="presentation" cellpadding="0" cellspacing="0" style="font-size:14px">${factRows(resultFacts)}</table>` : ""}` : "")}
        ${error ? section("Error", `<div style="background:#fef2f2;border:1px solid #fecaca;color:#b91c1c;border-radius:8px;padding:10px 12px;font-size:13px;word-break:break-word">${esc(error)}</div>`) : ""}
        ${links.length ? `<tr><td style="padding:22px 28px 0">${links.map((l) =>
            `<a href="${esc(l.url)}" style="display:inline-block;background:${p.color};color:#fff;text-decoration:none;border-radius:8px;padding:9px 16px;font-size:14px;font-weight:600;margin-right:8px">${esc(l.title ?? l.url)}</a>`).join("")}</td></tr>` : ""}
        <tr><td style="padding:24px 28px;color:#94a3b8;font-size:12px">
          ${[data.domain ? "Domain: " + esc(data.domain) : "", ts ? esc(ts) : "", actor ? "by " + esc(actor) : ""].filter(Boolean).join(" · ")}
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>`;

// ---------------------------------------------------------------- Adaptive Card
const body = [
  { type: "Container", style: p.card, bleed: true, items: [
    { type: "TextBlock", size: "Large", weight: "Bolder", wrap: true, text: `${p.emoji} ${title}` },
    { type: "TextBlock", isSubtle: true, spacing: "None", wrap: true,
      text: [p.label, subtitleBits, ts].filter(Boolean).join(" · ") },
  ] },
];
if (inputs.length) {
  body.push({ type: "TextBlock", weight: "Bolder", text: "Inputs", spacing: "Medium" });
  body.push({ type: "FactSet", facts: inputs.map((i) => ({ title: String(i.label), value: String(i.value) })) });
}
if (records.length) {
  body.push({ type: "TextBlock", weight: "Bolder", text: "DNS records", spacing: "Medium" });
  body.push({ type: "FactSet", facts: records.map((r) => ({
    title: `${r.name} (${r.type})`,
    value: `${r.value} · TTL ${r.ttl ?? "-"}${r.action ? " · " + r.action : ""}`,
  })) });
}
if (result.summary || resultFacts.length) {
  body.push({ type: "TextBlock", weight: "Bolder", text: "Result", spacing: "Medium" });
  if (result.summary) body.push({ type: "TextBlock", wrap: true, text: String(result.summary) });
  if (resultFacts.length) body.push({ type: "FactSet", facts: resultFacts.map((f) => ({ title: String(f.label), value: String(f.value) })) });
}
if (error) body.push({ type: "TextBlock", color: "Attention", wrap: true, text: `Error: ${error}`, spacing: "Medium" });

const card = {
  type: "message",
  attachments: [{
    contentType: "application/vnd.microsoft.card.adaptive",
    content: {
      type: "AdaptiveCard",
      $schema: "http://adaptivecards.io/schemas/adaptive-card.json",
      version: "1.4",
      msteams: { width: "Full" },
      body,
      actions: links.map((l) => ({ type: "Action.OpenUrl", title: String(l.title ?? l.url), url: String(l.url) })),
    },
  }],
};

// ---------------------------------------------------------------- Slack (Block Kit)
const slackEsc = (s) => String(s ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const chunk = (arr, n) => { const o = []; for (let i = 0; i < arr.length; i += n) o.push(arr.slice(i, i + n)); return o; };
// Slack sections allow at most 10 fields, each <= 2000 chars.
const fieldSections = (pairs, toText) => chunk(pairs, 10).map((grp) => ({
  type: "section",
  fields: grp.map((x) => ({ type: "mrkdwn", text: toText(x).slice(0, 2000) })),
}));

const blocks = [
  { type: "header", text: { type: "plain_text", text: `${p.emoji} ${title}`.slice(0, 150), emoji: true } },
  { type: "context", elements: [{ type: "mrkdwn",
    text: [`*${p.label}*`, subtitleBits, ts, actor && `by ${actor}`].filter(Boolean).map(slackEsc).join("  ·  ") }] },
];
if (inputs.length) {
  blocks.push({ type: "section", text: { type: "mrkdwn", text: "*Inputs*" } });
  blocks.push(...fieldSections(inputs, (i) => `*${slackEsc(i.label)}*\n${slackEsc(i.value)}`));
}
if (records.length) {
  blocks.push({ type: "section", text: { type: "mrkdwn", text: "*DNS records*" } });
  blocks.push(...fieldSections(records, (r) =>
    `*${slackEsc(r.name)}* (${slackEsc(r.type)})\n${slackEsc(r.value)} · TTL ${r.ttl ?? "-"}${r.action ? " · " + slackEsc(r.action) : ""}`));
}
if (result.summary) blocks.push({ type: "section", text: { type: "mrkdwn", text: `*Result*\n${slackEsc(result.summary)}` } });
if (resultFacts.length) blocks.push(...fieldSections(resultFacts, (f) => `*${slackEsc(f.label)}*\n${slackEsc(f.value)}`));
if (error) blocks.push({ type: "section", text: { type: "mrkdwn", text: `:warning: *Error*\n${slackEsc(error)}` } });
if (links.length) blocks.push({ type: "actions", elements: links.slice(0, 5).map((l) => ({
  type: "button", text: { type: "plain_text", text: String(l.title ?? l.url).slice(0, 75) }, url: String(l.url) })) });

const slack = {
  text: `${p.emoji} ${p.label}: ${title}${result.summary ? " — " + result.summary : ""}`,
  attachments: [{ color: p.color, blocks }],
};

// ---------------------------------------------------------------- plain text (email fallback / generic)
const txt = [];
txt.push(`[${p.label}] ${title}`);
if (subtitleBits) txt.push(subtitleBits);
const meta = [data.domain && `domain: ${data.domain}`, ts, actor && `by ${actor}`].filter(Boolean).join(" · ");
if (meta) txt.push(meta);
if (inputs.length) { txt.push("", "Inputs:"); inputs.forEach((i) => txt.push(`  ${i.label}: ${i.value}`)); }
if (records.length) { txt.push("", "DNS records:"); records.forEach((r) => txt.push(`  ${r.name} (${r.type}) = ${r.value}  TTL=${r.ttl ?? "-"}${r.action ? "  [" + r.action + "]" : ""}`)); }
if (result.summary || resultFacts.length) { txt.push("", "Result:"); if (result.summary) txt.push(`  ${result.summary}`); resultFacts.forEach((f) => txt.push(`  ${f.label}: ${f.value}`)); }
if (error) txt.push("", `Error: ${error}`);
if (links.length) { txt.push("", "Links:"); links.forEach((l) => txt.push(`  ${l.title ?? l.url}: ${l.url}`)); }

// ---------------------------------------------------------------- write
mkdirSync(outDir, { recursive: true });
const artifacts = {
  "report.html": html,                          // email (HTML)
  "report.txt": txt.join("\n") + "\n",           // email plain-text fallback / generic
  "card.json": JSON.stringify(card, null, 2),    // Teams (Adaptive Card, Power Automate envelope)
  "slack.json": JSON.stringify(slack, null, 2),  // Slack (Block Kit + colored attachment)
};
const written = Object.entries(artifacts).map(([name, content]) => {
  const path = join(outDir, name);
  writeFileSync(path, content, "utf8");
  return path;
});
console.log("Wrote:\n" + written.map((x) => "  " + x).join("\n"));
