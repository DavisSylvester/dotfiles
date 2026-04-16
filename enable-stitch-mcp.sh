#!/bin/bash
# Toggle Stitch MCP server for Claude Code
# Usage: ./enable-stitch-mcp.sh [on|off]

if [ "$1" = "off" ]; then
  claude mcp remove stitch
  echo "Stitch MCP disabled"
else
  claude mcp add stitch -- npx @anthropic-ai/stitch-mcp
  echo "Stitch MCP enabled"
fi
