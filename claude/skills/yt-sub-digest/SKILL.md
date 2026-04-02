---
name: yt-sub-digest
description: Fetch yesterday's YouTube subscription videos, categorize with Claude Sonnet, and send digest via email + Telegram
argument-hint: [run|auth|test]
---

# YouTube Subscription Daily Digest

Run the YouTube subscription digest pipeline on demand.

## Commands

### Default: `run` (or no argument)
Execute the full digest pipeline:
1. Authenticate with Google OAuth 2.0
2. Fetch all YouTube subscriptions
3. Get videos published yesterday from each channel
4. Categorize videos using Claude Sonnet
5. Send HTML email digest via Resend
6. Send formatted message via Telegram

```bash
cd c:/projects/davisSylvester/yt-sub-digest && bun src/jobs/run-digest.mts
```

### `auth`
Run the one-time OAuth authorization flow to get a Google refresh token:

```bash
cd c:/projects/davisSylvester/yt-sub-digest && bun src/auth/authorize.mts
```

After authorization, copy the refresh token into the `.env` file as `GOOGLE_REFRESH_TOKEN`.

### `test`
Run the test suite:

```bash
cd c:/projects/davisSylvester/yt-sub-digest && bun test
```

## Troubleshooting

- **"GOOGLE_REFRESH_TOKEN not set"** — Run `/yt-sub-digest auth` first
- **"TELEGRAM_CHAT_ID not set"** — Message the bot on Telegram, then run: `curl https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates` to find your chat ID
- **"No new videos found"** — Normal if no subscriptions posted yesterday
- **Quota errors** — YouTube API quota resets at midnight Pacific. 100 subs uses ~302 units of the 10,000 daily limit.

## Project Location
`c:\projects\davisSylvester\yt-sub-digest`

## Cron Schedule
The project also runs as a cron job at **5:00 AM CST daily** via `bun src/index.mts`.
Start the cron daemon: `cd c:/projects/davisSylvester/yt-sub-digest && bun src/index.mts`
