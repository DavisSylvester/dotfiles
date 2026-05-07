#!/usr/bin/env bash
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build directory segment: show last 2 path components
dir_display=$(echo "$cwd" | awk -F'/' '{
  n = NF
  if (n == 0) { print "/"; exit }
  if (n == 1) { print "/"; exit }
  if (n == 2) { print $2; exit }
  print $(n-1) "/" $n
}')

# Context usage segment (only when data is available)
ctx_segment=""
if [ -n "$used" ]; then
  ctx_segment=" | ctx: $(printf '%.0f' "$used")%"
fi

printf '%s | %s%s' "$dir_display" "$model" "$ctx_segment"
