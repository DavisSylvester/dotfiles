---
name: davaco-status
description: Generate Davis's bi-weekly Davaco status report for upper management. Imports each direct report's submitted status from status-reports/team/<name>/, carries forward unfinished items from the previous report, prompts Davis for his own updates, writes the Markdown master, and exports styled .docx + .pdf. Use when Davis says "new status report", "status report", "biweekly report", or "davaco status".
---

# Davaco Bi-Weekly Status Report

Generate the master status report Davis sends to upper management every other Thursday.

## Repo layout (under `~/docs/davaco/status-reports/`)

```
team/<name>/        # Davis uploads each direct report's file here (leonard, elliott, yasir, alex, kirk)
reports/YYYY-MM-DD/ # output: status-report-YYYY-MM-DD.{md,docx,pdf}
templates/status-report-template.md   # master template
templates/reference.docx               # docx style template (teal Title, green Heading2)
originals/          # archived legacy reports
```

Direct reports: **Leonard, Elliott, Yasir, Alex, Kirk**.

## Workflow

Create a TodoWrite item per step.

### 1. Determine the cycle date
- Cadence is **bi-weekly on Thursdays** (anchor examples: 2026-05-14, 2026-05-28, 2026-06-11, 2026-06-25 …).
- Default to the next report Thursday on/after today. Confirm the date with Davis if ambiguous.
- Title format: `STATUS REPORT – Month DD, YYYY`. Folder/file: `YYYY-MM-DD`.

### 2. Read the previous report
- Find the most recent folder under `reports/`. Read its `.md`.
- **Carry forward** every project/item still marked `In-progress`; drop ones marked `Completed` (unless completed *this* cycle — then keep under Completed for one cycle).

### 3. Import each direct report's status
- For each `team/<name>/` folder, read the **newest file** (by filename date or mtime). It may be `.docx`, `.txt`, `.md`, or `.pdf`.
  - `.docx`: `unzip -p file.docx word/document.xml | python3 -c "import sys,re,html;x=sys.stdin.read().replace('</w:p>','\n');print(html.unescape(re.sub(r'<[^>]+>','',x)))"`
  - `.pdf`: read it with the Read tool.
- Summarize each person's update into a `# WEEKLY TASKS - <Name>` section, matching the bullet style of the template.
- If a folder has no new file since the last cycle, add the section with `<!-- No submission yet for this cycle. -->` and tell Davis who is missing.

### 4. Gather Davis's own inputs
Ask Davis (one message, grouped) for anything that changed since last cycle:
- **Key Accomplishments** status per area (Network / Security / Cloud / Software Development) — default `Stable`.
- **Action Items** by area.
- **WEEKLY TASKS - Davis** — project updates (carry forward In-progress, add new, mark Completed).
- **Clearthread Rewrite Summary** — updated hours by month + Remaining.

### 5. Write the Markdown master
- Copy `templates/status-report-template.md` into `reports/<date>/status-report-<date>.md`.
- Fill the title block and all sections. Keep the YAML `title:` block (drives the docx Title style).

### 6. Export to .docx and .pdf
Run from the report folder:
```bash
cd ~/docs/davaco/status-reports/reports/<date>
pandoc status-report-<date>.md -o status-report-<date>.docx \
  --reference-doc=../../templates/reference.docx
/Applications/LibreOffice.app/Contents/MacOS/soffice --headless \
  --convert-to pdf --outdir . status-report-<date>.docx
```
- `pandoc` and LibreOffice (`soffice`) must be installed (`brew install pandoc`, `brew install --cask libreoffice`).
- Verify both files exist and are non-trivial in size, then report the paths to Davis.

## Style notes
- Source of truth is the Markdown; never hand-edit the `.docx`/`.pdf`.
- Heading mapping for fidelity: YAML `title:` → Title (teal), `#` → Heading1 (section), `##` → Heading2 (green sub-header).
- The Clearthread chart is a Markdown table in the `.md`; Davis can swap the pasted pie chart back into the `.docx` before sending if he wants the visual.
