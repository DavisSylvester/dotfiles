#!/usr/bin/env bash
# sync.sh — pull dotfiles, run install, email results
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EMAIL="dsylvesteriii@gmail.com"
SUBJECT="Dotfiles Sync — $(date '+%Y-%m-%d %H:%M')"
LOG=$(mktemp)

{
  echo "=== Dotfiles Sync: $(date) ==="
  echo ""

  cd "$DOTFILES_DIR"

  echo "--- git add & commit local changes ---"
  /usr/bin/git add -A 2>&1
  /usr/bin/git diff --cached --quiet 2>&1
  if [[ $? -ne 0 ]]; then
    /usr/bin/git commit -m "chore: auto-sync $(hostname) $(date '+%Y-%m-%d %H:%M')" 2>&1
  else
    echo "(no local changes to commit)"
  fi
  echo ""

  echo "--- git pull --rebase ---"
  /usr/bin/git pull --rebase origin main 2>&1
  PULL_EXIT=$?
  echo ""

  echo "--- git push ---"
  /usr/bin/git push origin main 2>&1
  PUSH_EXIT=$?
  echo ""

  echo "--- install.sh ---"
  /bin/bash "$DOTFILES_DIR/install.sh" 2>&1
  INSTALL_EXIT=$?
  echo ""

  if [[ $PULL_EXIT -eq 0 && $PUSH_EXIT -eq 0 && $INSTALL_EXIT -eq 0 ]]; then
    echo "Status: SUCCESS"
  else
    echo "Status: FAILED (pull=$PULL_EXIT, push=$PUSH_EXIT, install=$INSTALL_EXIT)"
  fi

  echo "=== Done: $(date) ==="
} > "$LOG" 2>&1

# Send email via Gmail SMTP (app password stored in macOS Keychain)
APP_PASSWORD=$(security find-generic-password -a "dsylvesteriii@gmail.com" -s "dotfiles-sync-smtp" -w 2>/dev/null)

if [[ -n "$APP_PASSWORD" ]]; then
  /usr/bin/python3 - "$EMAIL" "$SUBJECT" "$LOG" "$APP_PASSWORD" <<'PYEOF'
import sys, smtplib
from email.mime.text import MIMEText

to_addr, subject, log_path, password = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(log_path) as f:
    body = f.read()

msg = MIMEText(body)
msg["Subject"] = subject
msg["From"] = to_addr
msg["To"] = to_addr

with smtplib.SMTP_SSL("smtp.gmail.com", 465) as s:
    s.login(to_addr, password)
    s.send_message(msg)

print("Email sent successfully")
PYEOF
else
  echo "WARNING: Could not retrieve SMTP password from Keychain"
fi

# Also keep a copy in the persistent log
cat "$LOG" >> "$DOTFILES_DIR/../.claude/dotfiles-sync.log"
rm -f "$LOG"
