#!/bin/bash
# Amiguito installer — Claude Code status line companion
set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

echo ""
echo "  ✦ Installing amiguito — your Claude Code companion ✦"
echo ""

# Copy statusline script
cp statusline.sh "$CLAUDE_DIR/statusline.sh"
chmod +x "$CLAUDE_DIR/statusline.sh"
echo "  ✓ statusline.sh installed"

# Copy config (don't overwrite existing)
if [ ! -f "$CLAUDE_DIR/amiguito.conf" ]; then
  cp amiguito.conf "$CLAUDE_DIR/amiguito.conf"
  echo "  ✓ amiguito.conf created"
else
  echo "  ○ amiguito.conf already exists (skipped)"
fi

# Copy icon
cp amiguito-icon.png "$CLAUDE_DIR/amiguito-icon.png"
echo "  ✓ amiguito-icon.png installed"

# Check if settings.json exists and has statusLine
if [ -f "$SETTINGS" ]; then
  if grep -q '"statusLine"' "$SETTINGS"; then
    echo "  ○ statusLine already configured in settings.json"
  else
    echo ""
    echo "  ⚠ Add this to your ~/.claude/settings.json:"
    echo ""
    echo '    "statusLine": {'
    echo '      "type": "command",'
    echo '      "command": "~/.claude/statusline.sh"'
    echo '    }'
    echo ""
  fi
else
  echo ""
  echo "  ⚠ No settings.json found. Create ~/.claude/settings.json with:"
  echo ""
  echo '  {'
  echo '    "statusLine": {'
  echo '      "type": "command",'
  echo '      "command": "~/.claude/statusline.sh"'
  echo '    }'
  echo '  }'
  echo ""
fi

# Optional deps
echo ""
echo "  Optional: brew install gum lolcat"
echo "  (gum = auto-sizing speech bubbles, lolcat = rare rainbow mode)"
echo ""
echo "  ✦ amiguito installed! restart Claude Code to meet your new friend ✦"
echo ""
